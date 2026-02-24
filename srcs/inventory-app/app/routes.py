from flask import request, jsonify, Blueprint
from .models import Movie, db

movies_bp = Blueprint('movies', __name__, url_prefix='/api/movies/')

@movies_bp.route('/', methods=['GET'])
def get_movies():
    title = request.args.get('title')
    if title:
        movies = Movie.query.filter(Movie.title.ilike(f'%{title}%')).all()
    else:
        movies = Movie.query.all()
    return jsonify([movie.to_dict() for movie in movies]), 200

@movies_bp.route('/<int:movie_id>', methods=['GET'])
def get_movie(movie_id):
    movie = Movie.query.get_or_404(movie_id)
    return jsonify(movie.to_dict()), 200

@movies_bp.route('/', methods=['POST'])
def create_movie():
    data = request.get_json()
    new_movie = Movie(title=data['title'], description=data.get('description'))
    db.session.add(new_movie)
    db.session.commit()
    return jsonify(new_movie.to_dict()), 200

@movies_bp.route('/<int:movie_id>', methods=['PUT'])
def update_movie(movie_id):
    movie = Movie.query.get_or_404(movie_id)
    data = request.get_json()
    movie.title = data.get('title', movie.title)
    movie.description = data.get('description', movie.description)
    db.session.commit()
    return jsonify(movie.to_dict()), 200

@movies_bp.route('/<int:movie_id>', methods=['DELETE'])
def delete_movie(movie_id):
    movie = Movie.query.get_or_404(movie_id)
    db.session.delete(movie)
    db.session.commit()
    return jsonify({'message': 'Movie deleted'}), 200

@movies_bp.route('/', methods=['DELETE'])
def delete_all_movies():
    Movie.query.delete()
    db.session.commit()
    return jsonify({'message': 'All movies deleted'}), 200