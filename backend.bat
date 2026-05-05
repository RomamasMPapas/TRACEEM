@echo off
echo Starting Trace EM Backend...
cd backend
if not exist venv (
    echo Virtual environment not found. Please ensure venv exists in the backend folder.
    pause
    exit /b
)
call venv\Scripts\activate
python main.py
pause
