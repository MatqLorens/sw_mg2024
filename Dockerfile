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
