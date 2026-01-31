package main

import (
	"context"
	"database/sql"
	"errors"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"amirhossein_portfolio/internal/store"

	_ "github.com/jackc/pgx/v5/stdlib"
)

type PageData struct {
	ActiveTab     string
	Settings      store.Settings
	About         []string
	Skills        []store.SkillGroup
	Badges        []store.Badge
	BlogPosts     []store.BlogPost
	ResearchItems []store.ResearchItem
	ResearchPage  store.ResearchPage
	Experiences   []store.Experience
}

type Server struct {
	store     *store.Store
	templates map[string]*template.Template
}

func main() {
	port := getenv("PORT", "8080")
	databaseURL := getenv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/portfolio?sslmode=disable")

	st, err := store.Open(databaseURL)
	if err != nil {
		log.Fatalf("db open: %v", err)
	}
	defer st.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := st.EnsureSchema(ctx); err != nil {
		log.Fatalf("db schema: %v", err)
	}
	if err := st.SeedIfEmpty(ctx); err != nil {
		log.Fatalf("db seed: %v", err)
	}

	templates, err := loadTemplates()
	if err != nil {
		log.Fatalf("templates: %v", err)
	}

	srv := &Server{store: st, templates: templates}

	mux := http.NewServeMux()
	mux.HandleFunc("/", srv.handleRoot)
	mux.HandleFunc("/index.html", srv.handleIndex)
	mux.HandleFunc("/blog", srv.handleBlog)
	mux.HandleFunc("/blog.html", srv.handleBlog)
	mux.HandleFunc("/research", srv.handleResearch)
	mux.HandleFunc("/research.html", srv.handleResearch)
	mux.HandleFunc("/resume", srv.handleResume)
	mux.HandleFunc("/resume.html", srv.handleResume)

	mux.Handle("/assets/", http.StripPrefix("/assets/", http.FileServer(http.Dir("assets"))))
	mux.HandleFunc("/styles.css", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "styles.css")
	})

	log.Printf("listening on :%s", port)
	if err := http.ListenAndServe(":"+port, logRequests(mux)); err != nil {
		log.Fatalf("server: %v", err)
	}
}

func loadTemplates() (map[string]*template.Template, error) {
	funcs := template.FuncMap{
		"safeHTML": func(input string) template.HTML {
			return template.HTML(input)
		},
		"activeClass": func(active, target string) string {
			if active == target {
				return "active"
			}
			return ""
		},
	}

	names := []string{"index", "blog", "research", "resume", "research_detail"}
	out := make(map[string]*template.Template)
	for _, name := range names {
		path := filepath.Join("templates", name+".html")
		base := filepath.Base(path)
		tmpl, err := template.New(base).Funcs(funcs).ParseFiles(path)
		if err != nil {
			return nil, err
		}
		out[name] = tmpl
	}
	return out, nil
}

func (s *Server) handleIndex(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" && r.URL.Path != "/index.html" {
		http.NotFound(w, r)
		return
	}
	ctx := r.Context()
	settings, err := s.store.GetSettings(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	about, err := s.store.ListAboutParagraphs(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	skills, err := s.store.ListSkillGroups(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	badges, err := s.store.ListTrustBadges(ctx)
	if err != nil {
		respondError(w, err)
		return
	}

	data := PageData{
		ActiveTab: "about",
		Settings:  settings,
		About:     about,
		Skills:    skills,
		Badges:    badges,
	}
	s.render(w, "index", data)
}

func (s *Server) handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" || r.URL.Path == "/index.html" {
		s.handleIndex(w, r)
		return
	}
	if r.URL.Path == "/research/" {
		http.Redirect(w, r, "/research", http.StatusMovedPermanently)
		return
	}
	if strings.HasPrefix(r.URL.Path, "/research-") && strings.HasSuffix(r.URL.Path, ".html") {
		s.serveResearchDetail(w, r, researchSlug(r.URL.Path))
		return
	}
	http.NotFound(w, r)
}

func (s *Server) handleBlog(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/blog" && r.URL.Path != "/blog.html" {
		http.NotFound(w, r)
		return
	}
	ctx := r.Context()
	settings, err := s.store.GetSettings(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	posts, err := s.store.ListBlogPosts(ctx)
	if err != nil {
		respondError(w, err)
		return
	}

	data := PageData{
		ActiveTab: "blog",
		Settings:  settings,
		BlogPosts: posts,
	}
	s.render(w, "blog", data)
}

func (s *Server) handleResearch(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/research" && r.URL.Path != "/research.html" {
		http.NotFound(w, r)
		return
	}
	ctx := r.Context()
	settings, err := s.store.GetSettings(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	items, err := s.store.ListResearchItems(ctx)
	if err != nil {
		respondError(w, err)
		return
	}

	data := PageData{
		ActiveTab:     "research",
		Settings:      settings,
		ResearchItems: items,
	}
	s.render(w, "research", data)
}

func (s *Server) handleResume(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/resume" && r.URL.Path != "/resume.html" {
		http.NotFound(w, r)
		return
	}
	ctx := r.Context()
	settings, err := s.store.GetSettings(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	experiences, err := s.store.ListExperiences(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	badges, err := s.store.ListTrustBadges(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	skills, err := s.store.ListSkillGroups(ctx)
	if err != nil {
		respondError(w, err)
		return
	}

	data := PageData{
		ActiveTab:   "resume",
		Settings:    settings,
		Experiences: experiences,
		Badges:      badges,
		Skills:      skills,
	}
	s.render(w, "resume", data)
}

func (s *Server) serveResearchDetail(w http.ResponseWriter, r *http.Request, slug string) {
	ctx := r.Context()
	settings, err := s.store.GetSettings(ctx)
	if err != nil {
		respondError(w, err)
		return
	}
	page, err := s.store.GetResearchPage(ctx, slug)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			http.NotFound(w, r)
			return
		}
		respondError(w, err)
		return
	}

	data := PageData{
		ActiveTab:    "research",
		Settings:     settings,
		ResearchPage: page,
	}
	s.render(w, "research_detail", data)
}

func (s *Server) render(w http.ResponseWriter, name string, data PageData) {
	tmpl, ok := s.templates[name]
	if !ok {
		respondError(w, errors.New("template missing"))
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if err := tmpl.ExecuteTemplate(w, name+".html", data); err != nil {
		respondError(w, err)
	}
}

func researchSlug(path string) string {
	if strings.HasPrefix(path, "/research-") && strings.HasSuffix(path, ".html") {
		trimmed := strings.TrimPrefix(path, "/research-")
		trimmed = strings.TrimSuffix(trimmed, ".html")
		return trimmed
	}
	return ""
}

func respondError(w http.ResponseWriter, err error) {
	log.Printf("request error: %v", err)
	http.Error(w, "Internal Server Error", http.StatusInternalServerError)
}

func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
	})
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
