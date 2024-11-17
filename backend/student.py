from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import IntegrityError
from fastapi.middleware.cors import CORSMiddleware
from typing import List

# Configuración de la base de datos
DATABASE_URL = "mysql+mysqlconnector://root:maquitos12@localhost/student_db"
engine = create_engine(DATABASE_URL, connect_args={"charset": "utf8mb4"})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Modelo actualizado con el campo address
class Student(Base):
    __tablename__ = 'students'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), index=True)
    email = Column(String(100), unique=True, index=True)
    age = Column(Integer)
    address = Column(Text)  # Nuevo campo address

# Crear las tablas en la base de datos
Base.metadata.create_all(bind=engine)

app = FastAPI()

# Configuración CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelos Pydantic actualizados
class StudentBase(BaseModel):
    name: str
    email: str
    age: int
    address: str  # Nuevo campo

class StudentCreate(StudentBase):
    class Config:
        orm_mode = True

class StudentUpdate(StudentBase):
    class Config:
        orm_mode = True

class StudentResponse(StudentBase):
    id: int
    
    class Config:
        orm_mode = True

# Función para obtener la sesión de la base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Endpoint para obtener todos los estudiantes
@app.get("/students/", response_model=List[StudentResponse])
def get_students(db: Session = Depends(get_db)):
    students = db.query(Student).all()
    return students

# Endpoint para obtener un estudiante por ID
@app.get("/students/{student_id}", response_model=StudentResponse)
def get_student(student_id: int, db: Session = Depends(get_db)):
    student = db.query(Student).filter(Student.id == student_id).first()
    if student is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    return student

# Endpoint para crear un nuevo estudiante
@app.post("/students/", response_model=StudentResponse)
def create_student(student: StudentCreate, db: Session = Depends(get_db)):
    # Verificar si el email ya está registrado
    db_student = db.query(Student).filter(Student.email == student.email).first()
    if db_student:
        raise HTTPException(status_code=400, detail="El email ya está registrado")

    # Crear un nuevo estudiante con todos los campos
    db_student = Student(
        name=student.name,
        email=student.email,
        age=student.age,
        address=student.address  # Nuevo campo
    )
    
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student

# Endpoint para actualizar un estudiante
@app.put("/students/{student_id}", response_model=StudentResponse)
def update_student(student_id: int, student: StudentUpdate, db: Session = Depends(get_db)):
    db_student = db.query(Student).filter(Student.id == student_id).first()
    if db_student is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    
    # Verificar si el nuevo email ya existe (si se está cambiando)
    if student.email != db_student.email:
        existing_student = db.query(Student).filter(Student.email == student.email).first()
        if existing_student:
            raise HTTPException(status_code=400, detail="El email ya está registrado")

    # Actualizar todos los campos
    db_student.name = student.name
    db_student.email = student.email
    db_student.age = student.age
    db_student.address = student.address  # Nuevo campo
    
    db.commit()
    db.refresh(db_student)
    return db_student

# Endpoint para eliminar un estudiante
@app.delete("/students/{student_id}")
def delete_student(student_id: int, db: Session = Depends(get_db)):
    db_student = db.query(Student).filter(Student.id == student_id).first()
    if db_student is None:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    db.delete(db_student)
    db.commit()
    return {"message": "Estudiante eliminado correctamente"}