# Zadanie 1 - Systemy Wirtualizacji
Autor - Mateusz Gołąbek, IK 7.1
## 1. Serwer
Poniżej przedstawiony jest kod źródłowy serwera, będącego główną aplikacją. Napisany on został w języku C:
```c
#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define PORT 8080
#define LOG_FILE "server.log"

void log_startup();
void handle_client(int client_sock, struct sockaddr_in client_addr);

int main(){
	int server_fd, client_sock;
	struct sockaddr_in server_addr, client_addr;
	socklen_t addr_len = sizeof(client_addr);
	
	log_startup();

	if((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0){ //Tworzenie socketu
		perror("Error: socket creation failed");
		exit(EXIT_FAILURE);
	} 

	server_addr.sin_family = AF_INET;
	server_addr.sin_addr.s_addr = INADDR_ANY;
	server_addr.sin_port = htons(PORT);

	if(bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0){ //Bindowanie adresu serwera
		perror("Error: address bind failed");
		exit(EXIT_FAILURE);
	}

	if(listen(server_fd, 10) < 0){ //Nasłuch serwera
		perror("Error: listening failed");
		exit(EXIT_FAILURE);
	}

	printf("Server is listening on port %d...\n", PORT);

	while(1){ //Główna pętla obsługująca zapytania klienta
		if((client_sock = accept(server_fd, (struct sockaddr *)&client_addr, &addr_len)) < 0){
			perror("Error: client accept failed");
			exit(EXIT_FAILURE);
		}

		handle_client(client_sock, client_addr);
	}

	return 0;
}

void log_startup(){ //Otwarcie pliku logującego i wpisanie czasu startu serwera
	FILE *log = fopen(LOG_FILE, "a");
	if(!log){
		perror("Error: unable to open log file");
		exit(EXIT_FAILURE);
	}

	time_t current_time = time(NULL);
	fprintf(log, "Server started at: %s\n", ctime(&current_time));
	fprintf(log, "Author: Mateusz Gołąbek\n");
	fprintf(log, "Listening on port: %d\n\n", PORT);

	fclose(log);
}

void handle_client(int client_sock, struct sockaddr_in client_addr){ //Odpowiedź na klienta oraz przedstawienie strony
	char client_ip[INET_ADDRSTRLEN];
	inet_ntop(AF_INET, &client_addr.sin_addr, client_ip, INET_ADDRSTRLEN);
	
	time_t current_time = time(NULL);
	struct tm *client_time = localtime(&current_time);

	char response[512];
	snprintf(response, sizeof(response), //Właściwa strona przedstawiana klientowi
			"HTTP/1.1 200 OK\r\n"
			"Content-Type: text/html\r\n\r\n"
			"<html><body>"
			"<h1>Your IP: %s</h1>"
			"<h2>Date and Time: %s</h2>"
			"</body></html>\r\n",
			client_ip, asctime(client_time));
	
	send(client_sock, response, strlen(response), 0);
	close(client_sock);	
}
```
Zawartość pliku Makefile:
```
CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET = server

all: $(TARGET)

$(TARGET): main.c
	$(CC) $(CFLAGS) -o $(TARGET) main.c

clean:
	rm -f $(TARGET)
```

## 2. Plik Dockerfile
W obrazie użyty został najnowszy dostępny obraz Arch Linux. Do jego zbudowania wykorzystany został plik Dockerfile o poniższej zawartości:
```
#Etap 1 - budowanie aplikacji
FROM gcc:latest AS builder
WORKDIR /app
COPY src /app
RUN make

#Etap 2 - tworzenie finalnego obrazu
FROM archlinux:latest
WORKDIR /app
COPY --from=builder /app/server /app/
EXPOSE 8080
CMD ["./server"] 

```

## 3. Polecenia Docker i działanie aplikacji
a) zbudowanie
```
docker build -t zadanie1-server .
```
b) uruchomienie
```
docker run -d -p 8080:8080 zadanie1-server
```
c) sprawdzenie logów kontenera
```
docker logs <id_uruchomionego_kontenera>
```
d) sprawdzenie liczby warstw obrazu
```
docker image inspect zadanie1-server --format '{{.RootFS.Layers}}'
```

