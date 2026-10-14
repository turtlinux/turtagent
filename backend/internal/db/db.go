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

func (r *DatabaseReceiver) GetConversationItems() ([]models.ConversationItem, error) {
	var items []models.ConversationItem

	err := r.Db.View(func(txn *badger.Txn) error {
		opts := badger.DefaultIteratorOptions
		opts.PrefetchValues = true

		it := txn.NewIterator(opts)
		defer it.Close()

		prefix := []byte("conversations:")

		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()

			err := item.Value(func(val []byte) error {
				var convItem models.ConversationItem
				if err := json.Unmarshal(val, &convItem); err != nil {
					return err
				}
				items = append(items, convItem)
				return nil
			})
			if err != nil {
				return err
			}
		}

		return nil
	})
	if err != nil {
		return nil, err
	}
	
	return items, nil
}

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

