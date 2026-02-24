from .extensions import db

class Movie(db.Model):
    __tablename__ = 'movies'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)

# Méthode pour afficher l'objet (utile pour le débogage)
    def __repr__(self):
        return f'<Movie {self.id} {self.title} {self.description}>'

    # Méthode pour convertir l'objet en dictionnaire (pour JSON)
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description
        }