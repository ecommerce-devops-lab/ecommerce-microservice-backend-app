FROM eclipse-temurin:11-jre-alpine

ARG PROJECT_VERSION=0.1.0
ARG JAR_FILE=target/user-service-v${PROJECT_VERSION}.jar

# Create app directory
WORKDIR /app

# Add a non-root user to run the application
RUN addgroup -S spring && adduser -S spring -G spring

# Environment variables
ENV SPRING_PROFILES_ACTIVE=dev
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+UseContainerSupport"
ENV EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka/
ENV SPRING_CLOUD_CONFIG_URI=http://cloud-config:9296
ENV SPRING_ZIPKIN_BASE_URL=http://zipkin:9411/

# Copy the JAR file
COPY ${JAR_FILE} app.jar

# Change ownership to spring user
RUN chown -R spring:spring /app
USER spring

# Expose port
EXPOSE 8700

# Health check
HEALTHCHECK --interval=60s --timeout=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:8700/user-service/actuator/health || exit 1

# Run the jar
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -jar app.jar"]
