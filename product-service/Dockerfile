# Build stage
FROM maven:3.8.4-eclipse-temurin-11 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn install -N -DskipTests

COPY product-service/pom.xml .
COPY product-service/src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:11-jre-alpine

ARG PROJECT_VERSION=0.1.0
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=dev
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseContainerSupport" 
ENV CACHE_ENABLED=true


COPY --from=build /workspace/target/product-service-*.jar app.jar
RUN chown -R spring:spring /app
USER spring

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8500/actuator/health || exit 1

EXPOSE 8500
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -jar app.jar"]