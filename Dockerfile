# Use official Python image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy source files
COPY app.py .

# Install Flask
RUN pip install flask

# Expose the port used in ECS (matches your taskdef/appspec)
EXPOSE 8080

# Command to run the app
CMD ["python", "app.py"]
