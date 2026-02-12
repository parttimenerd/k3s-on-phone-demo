FROM maven:3.9.9-eclipse-temurin-25 AS builder
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://unpkg.com/lemonadejs@5.3.6/dist/lemonade.js \
	-o /workspace/src/main/resources/static/lemonade.min.js
RUN curl -fsSL https://unpkg.com/prismjs@1.29.0/prism.js \
	-o /workspace/src/main/resources/static/prism.js
RUN curl -fsSL https://unpkg.com/prismjs@1.29.0/components/prism-json.min.js \
	-o /workspace/src/main/resources/static/prism-json.min.js
RUN curl -fsSL https://unpkg.com/prismjs@1.29.0/themes/prism-tomorrow.min.css \
	-o /workspace/src/main/resources/static/prism-tomorrow.min.css
RUN mvn -q -e -DskipTests package

FROM sapmachine:25-jre-alpine
WORKDIR /app
COPY --from=builder /workspace/target/phone-chat-1.0.0.jar /app/chat.jar
EXPOSE 8080
ENV PORT=8080
CMD ["java", "-jar", "/app/chat.jar"]
