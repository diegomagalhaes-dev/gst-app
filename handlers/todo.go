package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/diegomagalhaes-dev/gst-app/database"
	"github.com/gorilla/mux"
	"github.com/seu-usuario/todo-app/models"
)

// Get all todos
func GetTodos(w http.ResponseWriter, r *http.Request) {
	var todos []models.Todo
	database.DB.Find(&todos)
	json.NewEncoder(w).Encode(&todos)
}

// Get single todo
func GetTodoByID(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	var todo models.Todo
	database.DB.First(&todo, params["id"])
	json.NewEncoder(w).Encode(&todo)
}

// Create a new todo
func CreateTodo(w http.ResponseWriter, r *http.Request) {
	var todo models.Todo
	json.NewDecoder(r.Body).Decode(&todo)
	database.DB.Create(&todo)
	json.NewEncoder(w).Encode(&todo)
}

// Update an existing todo
func UpdateTodo(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	var todo models.Todo
	database.DB.First(&todo, params["id"])
	json.NewDecoder(r.Body).Decode(&todo)
	database.DB.Save(&todo)
	json.NewEncoder(w).Encode(&todo)
}

// Delete a todo
func DeleteTodo(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	var todo models.Todo
	database.DB.Delete(&todo, params["id"])
	json.NewEncoder(w).Encode("Todo deleted successfully")
}
