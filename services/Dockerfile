# Use a base image with Java and Maven
#FROM eclipse-temurin:17
FROM maven:3.8.7-openjdk-18-slim



# Set the working directory in the container
WORKDIR /app

# Copy the pom.xml and source code
COPY pom.xml .
COPY library library

WORKDIR library

RUN mvn clean install

ENTRYPOINT ["java", "-cp", "target/bq-pii-classifier-library-2.0.0-jar-with-dependencies.jar", "com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.gcs.PubSubStressTesting"]
