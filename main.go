package main

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"

	"server-go/common"
	"server-go/database"
	"server-go/routes"
)

func main() {

	common.InitCache()

	database.InitDB()

	mux := chi.NewRouter()

	mux.Use(routes.CorsMiddleware)

	mux.Handle("/*", http.FileServer(http.Dir("./game")))

	mux.HandleFunc("/ws", routes.WS)

	mux.HandleFunc("/webhook", routes.Webhook)

	mux.HandleFunc("/error", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "An Error occurred\n")
	})

	fmt.Printf("server started at http://localhost:%s\n", common.Config.Port)

	err := http.ListenAndServe(":"+common.Config.Port, mux)
	if errors.Is(err, http.ErrServerClosed) {
		fmt.Printf("server closed\n")

	} else if err != nil {
		fmt.Printf("error starting server: %s\n", err)
		os.Exit(1)
	}
}
