from app.core.enums import VehicleStatus


VALID_TRANSITIONS: dict[VehicleStatus, set[VehicleStatus]] = {
    VehicleStatus.AVAILABLE: {
        VehicleStatus.RESERVED,
        VehicleStatus.RENTED,
        VehicleStatus.UNDER_MAINTENANCE,
        VehicleStatus.OUT_OF_SERVICE
    },
    VehicleStatus.RESERVED: {
        VehicleStatus.RENTED,
        VehicleStatus.AVAILABLE
    },
    VehicleStatus.RENTED: {
        VehicleStatus.RETURNED,
        VehicleStatus.ACCIDENT
    },
    VehicleStatus.RETURNED: {
        VehicleStatus.UNDER_INSPECTION
    },
    VehicleStatus.UNDER_INSPECTION: {
        VehicleStatus.AVAILABLE,
        VehicleStatus.UNDER_MAINTENANCE
    },
    VehicleStatus.UNDER_MAINTENANCE: {
        VehicleStatus.AVAILABLE,
        VehicleStatus.OUT_OF_SERVICE
    },
    VehicleStatus.ACCIDENT: {
        VehicleStatus.UNDER_MAINTENANCE,
        VehicleStatus.OUT_OF_SERVICE
    },
    VehicleStatus.OUT_OF_SERVICE: {
        VehicleStatus.AVAILABLE,
        VehicleStatus.SOLD_ARCHIVED
    },
    VehicleStatus.SOLD_ARCHIVED: set()
}


def can_transition(current_status: VehicleStatus, target_status: VehicleStatus) -> bool:
    if current_status == target_status:
        return True
    allowed = VALID_TRANSITIONS.get(current_status, set())
    return target_status in allowed


def validate_status_transition(current_status: VehicleStatus, target_status: VehicleStatus) -> None:
    if not can_transition(current_status, target_status):
        allowed = [s.value for s in VALID_TRANSITIONS.get(current_status, set())]
        raise ValueError(
            f"Invalid vehicle status transition from '{current_status.value}' to '{target_status.value}'. "
            f"Allowed next statuses: {allowed}"
        )

