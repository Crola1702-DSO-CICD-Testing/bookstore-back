FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests && \
    mv target/bookstore-back-*.jar target/app.jar

FROM build AS test-deps
RUN apt-get update && apt-get install -y nodejs npm && \
    npm install -g newman postman-combine-collections
COPY collections ./collections

FROM test-deps AS unit-tests
RUN mvn verify -Punit-tests

FROM test-deps AS integration-tests
RUN mvn verify -Pintegration-tests

FROM build AS static-analysis
ARG SONARQUBE_URL=http://sonarqube:9000
RUN --mount=type=secret,id=sonar_token \
    SONAR_TOKEN=$(cat /run/secrets/sonar_token) \
    mvn sonar:sonar \
        -Dsonar.token=${SONAR_TOKEN} \
        -Dsonar.host.url=${SONARQUBE_URL}

FROM eclipse-temurin:21-jre-alpine AS runtime
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=build /app/target/app.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
