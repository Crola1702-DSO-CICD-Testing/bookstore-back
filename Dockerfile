FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests && \
    mv target/bookstore-back-*.jar target/app.jar

FROM build AS test
RUN apt-get update && apt-get install -y nodejs npm && \
    npm install -g newman
COPY collections ./collections
RUN mvn test
RUN java -jar target/app.jar & \
    sleep 20 && \
    newman run --env-var baseUrl=http://127.0.0.1:8080/api collections/*.postman_collection.json

FROM eclipse-temurin:21-jre-alpine AS runtime
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=build /app/target/app.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
