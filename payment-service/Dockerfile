# Build stage
FROM maven:3.8.4-eclipse-temurin-11 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn install -N -DskipTests

COPY payment-service/pom.xml .
COPY payment-service/src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:11-jre-alpine

ARG PROJECT_VERSION=0.1.0
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=dev
ENV JAVA_OPTS="-Xms384m -Xmx768m -XX:+UseG1GC -XX:+UseContainerSupport"
ENV PAYMENT_GATEWAY_TIMEOUT=5000

COPY --from=build /workspace/target/payment-service-*.jar app.jar
RUN chown -R spring:spring /app
USER spring

HEALTHCHECK --interval=20s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8400/actuator/health || exit 1

EXPOSE 8400
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -jar app.jar"]