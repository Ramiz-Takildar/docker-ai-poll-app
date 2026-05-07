"""
Flask Application for AI Poll Voting System
Provides API endpoints for voting and retrieving results
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for
from database import init_db, add_vote, get_results
import os

# Initialize Flask application
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

# Initialize database connection on startup
try:
    init_db()
except Exception as e:
    print(f"Warning: Database initialization failed: {e}")

@app.route('/', methods=['GET'])
def index():
    """
    Home page route - Display poll question and voting buttons
    
    GET /: Renders the main voting page
    """
    return render_template('index.html')

@app.route('/vote', methods=['POST'])
def vote():
    """
    Vote submission endpoint
    
    POST /vote: Accepts vote submission and stores in database
    Expected JSON: {"option": "yes" or "no"}
    Returns: JSON with success status
    """
    try:
        # Get vote option from request
        data = request.get_json()
        option = data.get('option', '').lower()
        
        # Validate vote option
        if option not in ['yes', 'no']:
            return jsonify({'success': False, 'message': 'Invalid vote option'}), 400
        
        # Add vote to database
        if add_vote(option):
            return jsonify({'success': True, 'message': 'Vote recorded successfully'})
        else:
            return jsonify({'success': False, 'message': 'Failed to record vote'}), 500
            
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/results', methods=['GET'])
def results():
    """
    Results page route - Display voting statistics
    
    GET /results: Renders the results page with voting statistics
    """
    results_data = get_results()
    return render_template('results.html', results=results_data)

@app.route('/api/results', methods=['GET'])
def api_results():
    """
    API endpoint for voting results
    
    GET /api/results: Returns voting statistics as JSON
    Used by frontend for live updates without page refresh
    """
    results_data = get_results()
    return jsonify(results_data)

@app.route('/health', methods=['GET'])
def health():
    """
    Health check endpoint
    
    GET /health: Returns application status
    Used by Docker healthcheck to verify container is running
    """
    try:
        results_data = get_results()
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 503

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors gracefully"""
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(error):
    """Handle 500 errors gracefully"""
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Run Flask development server
    # In production, use a WSGI server like Gunicorn
    app.run(
        host='0.0.0.0',  # Listen on all network interfaces (required for Docker)
        port=5000,
        debug=os.getenv('FLASK_ENV') == 'development'
    )
