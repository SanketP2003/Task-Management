from sqlalchemy.orm import Session

from app.models.category import Category


def get_categories(db: Session, *, user_id: int) -> list[Category]:
    return (
        db.query(Category)
        .filter(Category.user_id == user_id)
        .order_by(Category.name.asc())
        .all()
    )


def get_category(db: Session, *, category_id: int, user_id: int) -> Category | None:
    return (
        db.query(Category)
        .filter(Category.id == category_id, Category.user_id == user_id)
        .first()
    )


def create_category(db: Session, *, user_id: int, name: str) -> Category:
    category = Category(user_id=user_id, name=name.strip())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


def update_category(db: Session, *, category_id: int, user_id: int, name: str) -> Category | None:
    category = get_category(db, category_id=category_id, user_id=user_id)
    if category is None:
        return None

    category.name = name.strip()
    db.commit()
    db.refresh(category)
    return category


def delete_category(db: Session, *, category_id: int, user_id: int) -> bool:
    category = get_category(db, category_id=category_id, user_id=user_id)
    if category is None:
        return False

    db.delete(category)
    db.commit()
    return True
