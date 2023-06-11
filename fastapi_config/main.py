from fastapi import status, FastAPI, Response
from pymongo import MongoClient

import database, json, requests
from fastapi.responses import JSONResponse
from datetime import datetime, timedelta
import certifi
import math, time
from config import MONGODB_URL, google_maps_api_key

from pydantic import BaseModel

from calculate import calculate_distance


app = FastAPI()

# config
is_login = False


client = MongoClient(MONGODB_URL, tlsCAFile=certifi.where())
db = client["subway"]  # 사용할 데이터베이스 이름
users_collection = db["users"]
stations_collection = db["station_latlng"]
packages_collection = db["packages"]


class UserCreateRequest(BaseModel):
    email: str
    password: str

@app.post('/signup')
def signup(user: UserCreateRequest, response: Response) -> dict:
    email = user.email
    password = user.password

    # 이미 등록된 사용자인지 확인
    existing_user = users_collection.find_one({"email": email})
    if existing_user is not None:
        response.status_code = status.HTTP_409_CONFLICT
        return {"message": "User already exists."}

    # 사용자 등록
    users_collection.insert_one({
        "email": email,
        "password": password,
        "rating": 3.0,
        "request_count": 0,
        "accept_count": 0
    })

    response.status_code = status.HTTP_201_CREATED
    return {"message": "User registered successfully."}



@app.post('/login')
def login(body: dict, response: Response) -> dict:
    print(f'You sent: \n{body}')
    username = body['email']
    password = body['password']

    # MongoDB에서 사용자 인증 검사
    user = users_collection.find_one({"email": username, "password": password})
    if user is None:
        response.status_code = status.HTTP_401_UNAUTHORIZED
        return {"message": "Login failed."}

    # 로그인 성공 시 처리
    response.status_code = status.HTTP_200_OK
    return {"message": "Login successful.",
            "items": {
                "items_public": 'items_in_public',
                "items_private": 'items_in_private'
            }
    }
            


@app.get('/stations/{address}')
def get_nearby_stations(address: str, email: str) -> JSONResponse:
    # Google Maps Geocoding API를 사용하여 주소의 좌표 정보를 가져옴
    response = requests.get(
        f'https://maps.googleapis.com/maps/api/geocode/json?address={address}&key={google_maps_api_key}'
    )
    if response.status_code == 200:
        result = response.json()
        if result['status'] == 'OK' and len(result['results']) > 0:
            location = result['results'][0]['geometry']['location']
            lat = location['lat']
            lng = location['lng']
            print(lat, lng)

            # 사용자의 lat와 lng 값을 업데이트
            users_collection.update_one(
                {"email": email},
                {"$set": {"lat": lat, "lng": lng}}
            )

            # MongoDB에서 가까운 지하철역 정보 가져오기
            nearby_stations = stations_collection.find({}, {'_id': 0})

            station_list = []
            for station in nearby_stations:
                station_lat = station['lat']
                station_lng = station['lng']

                # 위도 및 경도 간의 직선거리 계산
                distance = calculate_distance(lat, lng, station_lat, station_lng)

                station_list.append({
                    'stationName': station['station'],
                    'distance': distance
                })

            # distance를 기준으로 station_list를 정렬
            station_list.sort(key=lambda x: x['distance'])

            # 상위 3개의 지하철역만 추출
            station_list = station_list[:3]

            return JSONResponse(content=station_list, media_type="application/json; charset=utf-8")
        else:
            return JSONResponse(content={'error': 'Failed to geocode address'}, status_code=400,
                                media_type="application/json; charset=utf-8")
    else:
        return JSONResponse(content={'error': 'Failed to connect to Geocoding API'}, status_code=500,
                            media_type="application/json; charset=utf-8")


class UserUpdatePackage(BaseModel):
    location: str
    lockerNumber: str
    password: str
    selectedStation: str
    selectedTime: str
    lat: float
    lng: float


# 두 지점의 직선거리를 계산하는 함수
def haversine_distance(lat1, lng1, lat2, lng2):
    # 지구의 반지름 (단위: km)
    R = 6371

    # 위도와 경도를 라디안으로 변환
    lat1_rad = math.radians(lat1)
    lng1_rad = math.radians(lng1)
    lat2_rad = math.radians(lat2)
    lng2_rad = math.radians(lng2)

    # 위도와 경도의 차이 계산
    delta_lat = lat2_rad - lat1_rad
    delta_lng = lng2_rad - lng1_rad

    # 하버사인 공식 적용
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lng/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    d = R * c

    return d

@app.post('/update-package')
def update_package(request: UserUpdatePackage) -> JSONResponse:
    # 요청에서 필요한 정보 추출
    location = request.location
    locker_number = request.lockerNumber
    password = request.password
    selected_station = request.selectedStation
    selected_time = request.selectedTime
    lat = request.lat
    lng = request.lng

    # "0001-01-01T18:03:00Z" 형식의 문자열을 파싱하여 datetime 객체로 변환
    selected_time_dt = datetime.strptime(selected_time, "%Y-%m-%dT%H:%M:%SZ")

    # MongoDB에서 조건에 맞는 사용자 검색
    matching_users = users_collection.find({
        "selectedStation": selected_station})

    # 검색된 모든 사용자의 package 업데이트
    for user in matching_users:
        user_selected_time = user.get("selectedTime")
        user_selected_time_dt = datetime.strptime(user_selected_time, "%Y-%m-%dT%H:%M:%SZ")
        time_diff = selected_time_dt - user_selected_time_dt
        time_diff_minutes = time_diff.total_seconds() // 60

        user_lat = user.get("lat")
        user_lng = user.get("lng")
        distance = haversine_distance(lat, lng, user_lat, user_lng)

        user_rating = user.get("rating")

        user_request_count = user.get("request_count")
        user_accept_count = user.get("accept_count")
        acceptance_rate = user_accept_count / user_request_count


        score = ((1 / time_diff_minutes) * 10) + ((1 / distance) * 15) + (user_rating * 5) + (acceptance_rate * 5)

        if user_rating <= 2:
            score /= 2
        if acceptance_rate <= 0.1:
            score /= 2

        # 패키지 정보 생성
        package = {
            "location": location,
            "lockerNumber": locker_number,
            "password": password,
            "score": score,
            "received_selection": False,
        }

        # 사용자 문서에 package 필드 추가 또는 업데이트
        users_collection.update_one(
            {"_id": user["_id"]},
            {"$set": {"package": package}}
        )

    matching_users = users_collection.find({
        "selectedStation": selected_station})

    matching_users_list = list(matching_users)  # 커서를 리스트로 변환
    print('matching_users_list',len(matching_users_list))

    for i in range(0, len(matching_users_list), 10):
        top_10_users = sorted(matching_users_list[i:i + 10], key=lambda user: user["package"]["score"], reverse=True)

        # top_10_users 리스트에 저장된 유저들의 package의 received_selection 값을 True로 변경하는 코드
        for user in top_10_users:
            users_collection.update_one(
                {"_id": user["_id"]},
                {"$set": {"package.received_selection": True},
                 "$inc": {"request_count": 1}}
            )

            time.sleep(5)

            # packages 컬렉션에서 중복 패키지 확인
            existing_package = packages_collection.find_one({
                "location": location,
                "lockerNumber": locker_number,
                "password": password
            })

            if existing_package:
                break

    return JSONResponse(content={"message": "Package updated successfully."})



@app.get('/check-package')
async def check_package(email: str) -> JSONResponse:
    # 이메일 값을 가진 문서 검색
    user = users_collection.find_one({"email": email})

    if user is None or 'package' not in user or not user['package'].get('received_selection', False):
        # 패키지 필드가 없거나 received_selection이 False인 경우
        return JSONResponse(content={"accepted": False})

    # 패키지 필드가 있고 received_selection이 True인 경우
    package_data = user['package']
    encoded_package_data = json.dumps(package_data, ensure_ascii=False).encode('utf-8')
    return JSONResponse(content={"accepted": True, "package": encoded_package_data.decode('utf-8')})



@app.get('/package-info/{address}')
def get_package_info(address: str) -> JSONResponse:
    if address not in database.package_info:
        return JSONResponse(content={'message': '주소를 다시 확인해주세요.'}, status_code=404)
    return JSONResponse(content={'info': database.package_info[address]}, media_type="application/json; charset=utf-8")


class PackageCreateRequest(BaseModel):
    station: str
    destination: str
    lockerNumber: str
    password: str
    time: datetime

class ArrivalTimeRequest(BaseModel):
    email: str
    selectedStation: str
    selectedTime: str

@app.post('/arrival-time', status_code=status.HTTP_200_OK)
def update_arrival_time(request: ArrivalTimeRequest) -> JSONResponse:
    email = request.email
    selected_station = request.selectedStation

    # arrivalTime 값을 파싱하여 시간 형식 변환
    time_parts = request.selectedTime.split(':')
    hour = int(time_parts[0])
    minute = int(time_parts[1])

    if hour >= 12:
        hour = hour % 12 + 12

    selected_time = datetime(1, 1, 1, hour, minute).isoformat() + "Z"

    print(email, selected_station, selected_time)

    # 해당 이메일에 대한 사용자 데이터 업데이트
    result = users_collection.update_one(
        {"email": email},
        {"$set": {"selectedStation": selected_station, "selectedTime": selected_time}}
    )

    if result.modified_count > 0:
        return JSONResponse(content="Arrival time updated successfully.")
    else:
        return JSONResponse(content="Failed to update arrival time.", status_code=status.HTTP_400_BAD_REQUEST)


class PackageRequest(BaseModel):
    email: str
    location: str
    lockerNumber: str
    password: str


@app.post("/accept-package")
def accept_package(request: PackageRequest) -> JSONResponse:
    email = request.email
    location = request.location
    lockerNumber = request.lockerNumber
    password = request.password

    # 패키지 중복 확인
    existing_package = packages_collection.find_one({"location": location, "lockerNumber": lockerNumber, "password": password})
    if existing_package:
        users_collection.update_one(
            {"email": email},
            {"$set": {"package.received_selection": False}}
        )
        return JSONResponse(content={"message": "Package already exists."})

    users_collection.update_one(
        {"email": email},
        {"$inc": {"accept_count": 1}}
    )
    # 패키지 저장
    package = {
        "email": email,
        "location": location,
        "lockerNumber": lockerNumber,
        "password": password
    }
    packages_collection.insert_one(package)

    return JSONResponse(content={"message": "Package accepted successfully."})


@app.post("/delete-package")
def delete_package(request: PackageRequest) -> JSONResponse:
    email = request.email
    location = request.location
    lockerNumber = request.lockerNumber
    password = request.password

    # 패키지 삭제
    result = packages_collection.delete_one(
        {"email": email, "location": location, "lockerNumber": lockerNumber, "password": password})

    # users 컬렉션에서도 동일한 email을 가진 user의 package 삭제
    users_collection.update_one(
        {"email": email},
        {"$unset": {"package": ""}}
    )

    if result.deleted_count > 0:
        return JSONResponse(content={"message": "Package deleted successfully."})
    else:
        return JSONResponse(content={"message": "Package not found."})

