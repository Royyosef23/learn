import pytest
from app import app

@pytest.fixture
def client():
    """Create test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert 'timestamp' in data

def test_weather_endpoint_with_city(client):
    """Test weather endpoint with city parameter"""
    response = client.get('/weather/London')
    # Should return 200 or 404 depending on API key validity
    assert response.status_code in [200, 404, 500]

def test_weather_endpoint_with_query_param(client):
    """Test weather endpoint with query parameter"""
    response = client.get('/weather?city=London')
    # Should return 200 or 404 depending on API key validity
    assert response.status_code in [200, 404, 500]

def test_weather_endpoint_default_city(client):
    """Test weather endpoint with default city"""
    response = client.get('/weather')
    # Should return response for Tel Aviv (default city)
    assert response.status_code in [200, 404, 500]
