# Build stage
FROM maven:3.8.4-eclipse-temurin-11 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn install -N -DskipTests

COPY shipping-service/pom.xml .
COPY shipping-service/src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:11-jre-alpine

ARG PROJECT_VERSION=0.1.0
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=dev
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+UseContainerSupport"
ENV MAX_RETRY_ATTEMPTS=3

COPY --from=build /workspace/target/shipping-service-*.jar app.jar
RUN chown -R spring:spring /app
USER spring

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8600/actuator/health || exit 1

EXPOSE 8600
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -jar app.jar"]