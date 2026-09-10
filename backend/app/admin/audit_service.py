from typing import Any

from sqlalchemy.orm import Session

from app.admin.audit_models import AuditLog


def create_audit_log(
    db: Session,
    admin_id: int,
    action: str,
    entity_type: str,
    entity_id: int | None = None,
    description: str = "",
    metadata: dict[str, Any] | None = None,
) -> AuditLog:

    audit_log = AuditLog(
        admin_id=admin_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        description=description,
        metadata_json=metadata,
    )

    db.add(audit_log)

    return audit_log