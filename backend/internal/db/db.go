package db

import (
	"encoding/json"
	"os"
	"path/filepath"
	"turtagent/backend/internal/models"

	badger "github.com/dgraph-io/badger/v4"
)

type DatabaseReceiver struct {
	Db *badger.DB
}

func InitDb() (*DatabaseReceiver, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	storageDir := ".local/share/turtagent/"
	dbDir := "database/"
	databaseLocation := filepath.Join(home, storageDir, dbDir)

	db, err := badger.Open(badger.DefaultOptions(databaseLocation))
	if (err != nil) {
		return nil, err
	}

	return &DatabaseReceiver{
		Db: db,
	}, nil
}

func (r *DatabaseReceiver) CloseDb() {
	defer r.Db.Close()
}

// func (r *DatabaseReceiver) GetConversationItems() ([]models.ConversationItem, error) {
// 		var item models.ConversationItem
	
// 		err := r.Db.View(func(txn *badger.Txn) error {
// 			key := []byte("conversation:" + )
			
// 			badgerItem, err := txn.Get(key)
// 			if err != nil {
// 				return err
// 			}

// 			return badgerItem.Value(func(val []byte) error {
// 				return json.Unmarshal(val, &item)
// 			})
// 		})
// }

func (r *DatabaseReceiver) AddConversationItem(item models.ConversationItem) error {
	err := r.Db.Update(func(txn *badger.Txn) error {
		key := []byte("conversation:" + item.Id)

		data, err := json.Marshal(item);
		if err != nil {
			return err
		}

        return txn.Set(key, data)
	})
	if err != nil {
		return err
	}

	return nil
}

