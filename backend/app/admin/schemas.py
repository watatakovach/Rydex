

from datetime import datetime

from pydantic import BaseModel, ConfigDict


# ============================================================
# BASE CONFIG
# ============================================================

class ORMModel(BaseModel):
    """
    Base schema for SQLAlchemy ORM responses.
    Enables Pydantic v2 to read data directly from ORM objects.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )


# ============================================================
# DRIVER VERIFICATION
# ============================================================

class DriverVerification(BaseModel):
    is_verified: bool


# ============================================================
# PENDING DRIVER RESPONSE
# ============================================================

class PendingDriverResponse(ORMModel):
    id: int
    user_id: int
    license_number: str
    is_verified: bool
    is_online: bool


# ============================================================
# ADMIN USER / PASSENGER RESPONSE
# ============================================================

class AdminUserResponse(ORMModel):
    id: int
    full_name: str
    phone_number: str
    email: str | None = None
    role: str
    is_active: bool
    created_at: datetime


# ============================================================
# ADMIN RIDE RESPONSE
# ============================================================

class AdminRideResponse(ORMModel):
    id: int

    # --------------------------------------------------------
    # USERS
    # --------------------------------------------------------

    passenger_id: int
    driver_id: int | None = None

    # --------------------------------------------------------
    # PASSENGER
    # --------------------------------------------------------

    passenger_name: str
    passenger_phone: str | None = None

    # --------------------------------------------------------
    # DRIVER
    # --------------------------------------------------------

    driver_name: str | None = None
    driver_phone: str | None = None

    # --------------------------------------------------------
    # LOCATIONS
    # --------------------------------------------------------

    pickup_location: str | None = None
    destination: str | None = None

    pickup_latitude: float
    pickup_longitude: float

    destination_latitude: float
    destination_longitude: float

    # --------------------------------------------------------
    # LIVE DRIVER LOCATION
    # --------------------------------------------------------

    driver_latitude: float | None = None
    driver_longitude: float | None = None
    driver_location_updated_at: datetime | None = None

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    status: str

    # --------------------------------------------------------
    # FARES
    # --------------------------------------------------------

    estimated_fare: float | None = None
    final_fare: float | None = None

    # --------------------------------------------------------
    # RIDE METRICS
    # --------------------------------------------------------

    distance_km: float | None = None
    duration_minutes: float | None = None

    # --------------------------------------------------------
    # TIMELINE
    # --------------------------------------------------------

    requested_at: datetime
    accepted_at: datetime | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    cancelled_at: datetime | None = None

    # --------------------------------------------------------
    # CANCELLATION
    # --------------------------------------------------------

    cancellation_reason: str | None = None
    cancelled_by: str | None = None

    # --------------------------------------------------------
    # ADMIN AUDIT
    # --------------------------------------------------------

    admin_note: str | None = None
    admin_action: str | None = None
    admin_id: int | None = None
    admin_action_at: datetime | None = None


# ============================================================
# ADMIN DRIVER RESPONSE
# ============================================================

class AdminDriverResponse(ORMModel):
    id: int
    user_id: int

    # --------------------------------------------------------
    # USER INFORMATION
    # --------------------------------------------------------

    full_name: str
    phone_number: str
    email: str | None = None

    # --------------------------------------------------------
    # DRIVER DOCUMENTS
    # --------------------------------------------------------

    license_number: str
    driving_license_document: str | None = None
    national_id_document: str | None = None
    vehicle_document: str | None = None

    # --------------------------------------------------------
    # VEHICLE
    # --------------------------------------------------------

    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    vehicle_plate: str | None = None

    # --------------------------------------------------------
    # PHOTOS
    # --------------------------------------------------------

    profile_photo: str | None = None
    vehicle_photo: str | None = None

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    is_verified: bool
    is_online: bool
    is_active: bool

    # --------------------------------------------------------
    # RATINGS
    # --------------------------------------------------------

    average_rating: float | None = None
    rating_count: int = 0


# ============================================================
# ADMIN DRIVER DETAIL RESPONSE
# ============================================================

class AdminDriverDetailResponse(ORMModel):
    id: int
    user_id: int

    # --------------------------------------------------------
    # USER INFORMATION
    # --------------------------------------------------------

    full_name: str
    phone_number: str
    email: str | None = None

    role: str
    is_active: bool

    # --------------------------------------------------------
    # DRIVER STATUS
    # --------------------------------------------------------

    is_verified: bool
    is_online: bool

    # --------------------------------------------------------
    # PROFILE
    # --------------------------------------------------------

    profile_photo: str | None = None

    # --------------------------------------------------------
    # LICENSE
    # --------------------------------------------------------

    license_number: str

    # --------------------------------------------------------
    # VEHICLE
    # --------------------------------------------------------

    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    vehicle_plate: str | None = None
    vehicle_photo: str | None = None

    # --------------------------------------------------------
    # DOCUMENTS
    # --------------------------------------------------------

    driving_license_document: str | None = None
    national_id_document: str | None = None
    vehicle_document: str | None = None

    # --------------------------------------------------------
    # ACCOUNT
    # --------------------------------------------------------

    created_at: datetime

    # --------------------------------------------------------
    # RATINGS
    # --------------------------------------------------------

    average_rating: float | None = None
    rating_count: int = 0


# ============================================================
# DRIVER STATUS UPDATE
# ============================================================

class DriverStatusUpdate(BaseModel):
    is_active: bool


# ============================================================
# DRIVER PERFORMANCE
# ============================================================

class DriverPerformanceResponse(ORMModel):
    driver_id: int
    full_name: str

    total_rides: int
    completed_rides: int
    cancelled_rides: int
    active_rides: int

    completion_rate: float

    total_earnings: float
    average_fare: float

    is_online: bool
    is_verified: bool


# ============================================================
# DRIVER EARNINGS
# ============================================================

class DriverEarningsResponse(ORMModel):
    today: float
    this_week: float
    this_month: float
    lifetime: float

    completed_rides: int


# ============================================================
# RIDE DETAIL RESPONSE
# ============================================================

class RideDetailResponse(ORMModel):
    id: int

    # --------------------------------------------------------
    # PASSENGER
    # --------------------------------------------------------

    passenger_name: str
    passenger_phone: str | None = None

    # --------------------------------------------------------
    # DRIVER
    # --------------------------------------------------------

    driver_name: str | None = None
    driver_phone: str | None = None

    # --------------------------------------------------------
    # LOCATIONS
    # --------------------------------------------------------

    pickup_location: str | None = None
    destination: str | None = None

    pickup_latitude: float
    pickup_longitude: float

    destination_latitude: float
    destination_longitude: float

    # --------------------------------------------------------
    # LIVE DRIVER LOCATION
    # --------------------------------------------------------

    driver_latitude: float | None = None
    driver_longitude: float | None = None
    driver_location_updated_at: datetime | None = None

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    status: str

    # --------------------------------------------------------
    # FARES
    # --------------------------------------------------------

    estimated_fare: float | None = None
    final_fare: float | None = None

    # --------------------------------------------------------
    # RIDE METRICS
    # --------------------------------------------------------

    distance_km: float | None = None
    duration_minutes: float | None = None

    # --------------------------------------------------------
    # TIMELINE
    # --------------------------------------------------------

    requested_at: datetime
    accepted_at: datetime | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    cancelled_at: datetime | None = None

    # --------------------------------------------------------
    # CANCELLATION
    # --------------------------------------------------------

    cancellation_reason: str | None = None
    cancelled_by: str | None = None

    # --------------------------------------------------------
    # ADMIN AUDIT
    # --------------------------------------------------------

    admin_note: str | None = None
    admin_action: str | None = None
    admin_id: int | None = None
    admin_action_at: datetime | None = None


# ============================================================
# ADMIN RIDE ACTION REQUEST
# ============================================================

class RideActionRequest(BaseModel):
    reason: str | None = None


# ============================================================
# ADMIN RIDE ACTION RESPONSE
# ============================================================

class RideActionResponse(ORMModel):
    message: str
    ride_id: int
    status: str


# ============================================================
# ADMIN CREATE DRIVER
# ============================================================

class AdminCreateDriver(BaseModel):
    user_id: int
    license_number: str


# ============================================================
# ADMIN DASHBOARD STATISTICS
# ============================================================

class AdminDashboardStats(ORMModel):

    # --------------------------------------------------------
    # USERS
    # --------------------------------------------------------

    total_users: int
    total_drivers: int
    verified_drivers: int
    pending_driver_verifications: int
    online_drivers: int

    # --------------------------------------------------------
    # RIDES
    # --------------------------------------------------------

    active_rides: int
    completed_rides: int
    cancelled_rides: int
    total_rides: int

    # --------------------------------------------------------
    # REVENUE
    # --------------------------------------------------------

    todays_revenue: float
    total_revenue: float

    driver_earnings: float
    platform_commission: float

    # --------------------------------------------------------
    # RIDE ANALYTICS
    # --------------------------------------------------------

    average_ride_fare: float
    average_ride_distance: float
    average_ride_duration: float

    # --------------------------------------------------------
    # OTHER
    # --------------------------------------------------------

    new_registrations: int
    completion_rate: float


# ============================================================
# ANALYTICS DATA POINT
# ============================================================

class AnalyticsDataPoint(BaseModel):
    date: str
    rides: int
    revenue: float


# ============================================================
# RIDE STATUS ANALYTICS
# ============================================================

class RideStatusAnalytics(BaseModel):
    completed: int
    cancelled: int
    active: int


# ============================================================
# USER GROWTH ANALYTICS
# ============================================================

class UserGrowthAnalytics(BaseModel):
    date: str
    passengers: int
    drivers: int


# ============================================================
# ADMIN DASHBOARD ANALYTICS
# ============================================================

class AdminDashboardAnalytics(BaseModel):
    rides_over_time: list[AnalyticsDataPoint]
    ride_status: RideStatusAnalytics
    user_growth: list[UserGrowthAnalytics]


# ============================================================
# USER MANAGEMENT
# ============================================================

class AdminUserListResponse(ORMModel):
    id: int
    full_name: str
    phone_number: str
    email: str | None = None
    role: str
    is_active: bool
    created_at: datetime


# ============================================================
# ADMIN USER DETAIL
# ============================================================

class AdminUserDetailResponse(ORMModel):
    id: int
    full_name: str
    phone_number: str
    email: str | None = None
    role: str
    is_active: bool
    created_at: datetime


# ============================================================
# ADMIN USER STATUS UPDATE
# ============================================================

class AdminUserStatusUpdate(BaseModel):
    is_active: bool


# ============================================================
# ADMIN USER RIDE HISTORY
# ============================================================

class AdminUserRideResponse(ORMModel):
    id: int

    passenger_id: int
    driver_id: int | None = None

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    status: str

    # --------------------------------------------------------
    # LOCATIONS
    # --------------------------------------------------------

    pickup_location: str | None = None
    destination: str | None = None

    pickup_latitude: float
    pickup_longitude: float

    destination_latitude: float
    destination_longitude: float

    # --------------------------------------------------------
    # FARES
    # --------------------------------------------------------

    estimated_fare: float | None = None
    final_fare: float | None = None

    # --------------------------------------------------------
    # RIDE METRICS
    # --------------------------------------------------------

    distance_km: float | None = None
    duration_minutes: float | None = None

    # --------------------------------------------------------
    # TIMELINE
    # --------------------------------------------------------

    requested_at: datetime
    accepted_at: datetime | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    cancelled_at: datetime | None = None

    # --------------------------------------------------------
    # CANCELLATION
    # --------------------------------------------------------

    cancellation_reason: str | None = None
    cancelled_by: str | None = None


# ============================================================
# ADMIN USER CANCELLATION HISTORY
# ============================================================

class AdminUserCancellationResponse(ORMModel):
    id: int

    passenger_id: int
    driver_id: int | None = None

    status: str

    # --------------------------------------------------------
    # LOCATIONS
    # --------------------------------------------------------

    pickup_location: str | None = None
    destination: str | None = None

    pickup_latitude: float
    pickup_longitude: float

    destination_latitude: float
    destination_longitude: float

    # --------------------------------------------------------
    # CANCELLATION
    # --------------------------------------------------------

    cancellation_reason: str | None = None
    cancelled_by: str | None = None

    # --------------------------------------------------------
    # TIMELINE
    # --------------------------------------------------------

    requested_at: datetime
    cancelled_at: datetime | None = None


# ============================================================
# DRIVER PAYMENT HISTORY
# ============================================================

class AdminDriverPaymentResponse(ORMModel):
    id: int

    amount: float
    transaction_type: str
    description: str | None = None
    created_at: datetime


# ============================================================
# AUDIT LOG
# ============================================================

class AuditLogResponse(ORMModel):
    id: int
    admin_id: int

    action: str
    entity_type: str
    entity_id: int | None = None

    description: str
    metadata_json: dict | None = None

    created_at: datetime


class AuditLogListResponse(BaseModel):
    total: int
    logs: list[AuditLogResponse]


# ============================================================
# ADMIN NOTIFICATIONS
# ============================================================

class AdminNotificationResponse(ORMModel):
    id: int

    user_id: int

    type: str
    title: str
    message: str

    entity_type: str | None = None
    entity_id: int | None = None

    data: dict | None = None

    is_read: bool
    created_at: datetime


class AdminNotificationListResponse(BaseModel):
    total: int
    unread: int
    read: int

    notifications: list[AdminNotificationResponse]


class AdminNotificationCreate(BaseModel):
    user_id: int

    type: str
    title: str
    message: str

    entity_type: str | None = None
    entity_id: int | None = None

    data: dict | None = None


class AdminNotificationBroadcast(BaseModel):
    type: str
    title: str
    message: str

    entity_type: str | None = None
    entity_id: int | None = None

    data: dict | None = None


class AdminNotificationActionResponse(BaseModel):
    message: str
    notification_id: int | None = None
    affected: int | None = None


# ============================================================
# ADMIN SETTINGS
# ============================================================

