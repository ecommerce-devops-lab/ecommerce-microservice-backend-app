# Build stage
FROM maven:3.8.4-eclipse-temurin-11 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn install -N -DskipTests

COPY order-service/pom.xml .
COPY order-service/src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:11-jre-alpine

ARG PROJECT_VERSION=0.1.0
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=dev
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseContainerSupport -XX:MaxRAMPercentage=80.0"
ENV KAFKA_BOOTSTRAP_SERVERS=kafka:9092

COPY --from=build /workspace/target/order-service-*.jar app.jar
RUN chown -R spring:spring /app
USER spring

HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8300/actuator/health || exit 1

EXPOSE 8300
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -jar app.jar"]