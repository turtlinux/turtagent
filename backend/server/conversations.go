package server

import (
	"encoding/json"
	"net/http"
	"turtagent/backend/internal/db"
	"turtagent/backend/internal/models"
)

type ConversationsReceiver struct {
	DatabaseReceiver *db.DatabaseReceiver
}

func InitConversationsHandler() (*ConversationsReceiver, error) {
	r, err := db.InitDb()
	if err != nil {
		return nil, err
	}

	return &ConversationsReceiver{
		DatabaseReceiver: r,
	}, nil
}

func (cr *ConversationsReceiver) Get(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	conversations, err := cr.DatabaseReceiver.GetConversationItems()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(conversations); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (cr *ConversationsReceiver) Add(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	defer r.Body.Close()

	var conversationItem models.ConversationItem
	if err := json.NewDecoder(r.Body).Decode(&conversationItem); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := cr.DatabaseReceiver.AddConversationItem(conversationItem); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(conversationItem)
}
