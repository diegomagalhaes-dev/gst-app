package main

import (
	"log"
	"net/http"

	"github.com/diegomagalhaes-dev/sgt-app/database"
	"github.com/diegomagalhaes-dev/sgt-app/handlers"
	"github.com/diegomagalhaes-dev/sgt-app/models"
	"github.com/gorilla/mux"
)

func main() {
	database.ConnectDatabase()
	database.DB.AutoMigrate(&models.Todo{})

	r := mux.NewRouter()

	r.HandleFunc("/todos", handlers.GetTodos).Methods("GET")
	r.HandleFunc("/todos/{id}", handlers.GetTodoByID).Methods("GET")
	r.HandleFunc("/todos", handlers.CreateTodo).Methods("POST")
	r.HandleFunc("/todos/{id}", handlers.UpdateTodo).Methods("PUT")
	r.HandleFunc("/todos/{id}", handlers.DeleteTodo).Methods("DELETE")

	log.Fatal(http.ListenAndServe(":8000", r))
}
