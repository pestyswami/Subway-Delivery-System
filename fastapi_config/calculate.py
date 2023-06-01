import math

def calculate_distance(lat1, lng1, lat2, lng2):
    # 지구의 반지름 (단위: km)
    radius = 6371

    # 각도를 라디안으로 변환
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lng1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lng2)

    # 두 지점의 위도 및 경도 차이 계산
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    # 피타고라스의 정리를 활용하여 직선거리 계산
    distance = math.sqrt((radius * dlat) ** 2 + (radius * math.cos(lat1_rad) * dlon) ** 2)
    distance = round(distance, 1)

    return distance
