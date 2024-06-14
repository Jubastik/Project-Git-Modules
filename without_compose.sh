cd backend
pwd

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.23.0.9-1.fc40.x86_64
./gradlew clean build
docker build . -t git_mod_back
docker run -d \
        -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=docker \
        git_mod_back