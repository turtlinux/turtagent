package models

type AssistantMessage struct {
	IsThinking bool
	Text string
}

type ChatMessage struct {
	Assistant AssistantMessage
	User string
}

type ConversationItem struct {
	Id string
	Title string
	History []ConversationItem
	LastUpdated string
}