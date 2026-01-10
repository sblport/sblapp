// Quick API Endpoint Tester
// Run this in browser console or as a standalone HTML file

const baseUrl = 'https://jetty.test';
const token = 'YOUR_AUTH_TOKEN_HERE'; // Get this from localStorage after login

const endpoints = [
    { method: 'GET', url: '/api/eqp/operations', desc: 'List operations' },
    { method: 'GET', url: '/api/eqp/equipment', desc: 'List equipment' },
    { method: 'GET', url: '/api/eqp/activities', desc: 'List activities' },
    { method: 'GET', url: '/api/eqp/locations', desc: 'List locations' },
];

async function testEndpoint(method, url, desc) {
    try {
        const response = await fetch(baseUrl + url, {
            method: method,
            headers: {
                'Authorization': `Bearer ${token}`,
                'Accept': 'application/json',
            },
        });

        const status = response.status;
        const statusText = response.statusText;

        console.log(`✅ ${method} ${url} - ${status} ${statusText} - ${desc}`);

        if (status === 200) {
            const data = await response.json();
            console.log('   Response:', data);
        }

        return { url, status, ok: response.ok };
    } catch (error) {
        console.error(`❌ ${method} ${url} - ERROR - ${desc}`, error.message);
        return { url, status: 0, ok: false, error: error.message };
    }
}

async function testAllEndpoints() {
    console.log('🔍 Testing Equipment Operations API Endpoints...\n');

    for (const endpoint of endpoints) {
        await testEndpoint(endpoint.method, endpoint.url, endpoint.desc);
        await new Promise(resolve => setTimeout(resolve, 200)); // Small delay
    }

    console.log('\n✅ Testing complete!');
}

// Run the tests
testAllEndpoints();
