import React from 'react';
import ReactDOM from 'react-dom/client';
import architect from './project-architecture.png';

const treeStructure = `infra-repo/
├── apps
│   ├── api
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   └── service.yaml
│   ├── auth
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   └── service.yaml
│   ├── frontend
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   └── service.yaml
│   └── namespace.yaml
├── data
│   ├── image.png
│   ├── namespace.yaml
│   ├── postgres
│   │   ├── secrets.yaml
│   │   ├── service.yaml
│   │   └── statefulset.yaml
│   └── redis
│       ├── service.yaml
│       └── statefulset.yaml
├── deploy.sh
├── destroy.sh
├── ingress-controller
│   ├── cert-manager
│   │   ├── clusterissuer.yaml
│   │   ├── clusterrolebinding.yaml
│   │   ├── clusterrole.yaml
│   │   ├── crds.yaml
│   │   ├── deployment.yaml
│   │   ├── namespace.yaml
│   │   └── serviceaccount.yaml
│   ├── info.txt
│   ├── namespace.yaml
│   └── nginx-ingress.yaml
├── ingress-routes
│   ├── app-ingress.yaml
│   └── image.png
├── jenkins
│   ├── clusterrolebinding.yaml
│   ├── clusterrole.yaml
│   ├── ingress.yaml
│   ├── namespace.yaml
│   ├── pvc.yaml
│   ├── serviceaccount.yaml
│   ├── service.yaml
│   └── statefulset.yaml
├── src
│   ├── api
│   │   ├── Dockerfile
│   │   ├── index.js
│   │   └── package.json
│   ├── auth
│   │   ├── Dockerfile
│   │   ├── index.js
│   │   └── package.json
│   └── frontend
│       ├── Dockerfile
│       ├── package.json
│       ├── public
│       │   └── index.html
│       └── src
│           ├── index.js
│           └── project-architecture.png
├── storage
│   ├── install-longhorn.sh
│   ├── local-storage.yaml
│   └── longhorn.yaml
└── system
    ├── cluster-autoscaler.yaml
    ├── metrics-server.yaml
    └── monitoring
        ├── alertmanager.yaml
        ├── grafana.yaml
        ├── loki.yaml
        ├── namespace.yaml
        ├── prometheus.yaml
        └── promtail.yaml`;

function App() {
    return (
        <div style={{ fontFamily: 'Arial, sans-serif', margin: 0, padding: 0 }}>

            {/* Header */}
            <header style={{
                background: 'linear-gradient(135deg, #1a1a2e, #16213e)',
                color: 'white',
                padding: '40px 20px',
                textAlign: 'center'
            }}>
                <h1 style={{ margin: 0, fontSize: '2.5em' }}>🚀 DevOps Platform</h1>
                <p style={{ margin: '10px 0 0', opacity: 0.8, fontSize: '1.1em' }}>
                    CI/CD Pipeline • Kubernetes • Microservices • Monitoring
                </p>
            </header>

            {/* Architecture Diagram */}
            <section style={{ padding: '40px 20px', maxWidth: '1200px', margin: '0 auto' }}>
                <h2 style={{
                    borderBottom: '3px solid #1a1a2e',
                    paddingBottom: '10px',
                    color: '#1a1a2e'
                }}>
                    📐 System Architecture Blueprint
                </h2>
                <div style={{
                    background: '#f8f9fa',
                    borderRadius: '12px',
                    padding: '20px',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                    textAlign: 'center'
                }}>
                    <img
                        src={architect}
                        alt="DevOps Architecture Blueprint"
                        style={{
                            maxWidth: '100%',
                            height: 'auto',
                            borderRadius: '8px'
                        }}
                    />
                </div>
            </section>

            {/* Repository Structure */}
            <section style={{
                padding: '40px 20px',
                maxWidth: '1200px',
                margin: '0 auto',
                background: '#f8f9fa'
            }}>
                <h2 style={{
                    borderBottom: '3px solid #1a1a2e',
                    paddingBottom: '10px',
                    color: '#1a1a2e',
                    marginBottom: '20px'
                }}>
                    📁 Infrastructure Repository Structure
                </h2>
                <div style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    gap: '20px',
                    alignItems: 'start'
                }}>

                    {/* Tree View */}
                    <div style={{
                        background: '#1a1a2e',
                        color: '#00ff88',
                        padding: '20px',
                        borderRadius: '8px',
                        fontFamily: '"Fira Code", "Courier New", monospace',
                        fontSize: '13px',
                        lineHeight: '1.6',
                        overflowX: 'auto',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.3)'
                    }}>
                        <pre style={{ margin: 0, whiteSpace: 'pre' }}>
                            {treeStructure}
                        </pre>
                    </div>

                    {/* Summary Cards */}
                    <div>
                        <div style={cardStyle}>
                            <h3 style={{ margin: '0 0 10px' }}>📦 {treeStructure.split('\\n').filter(l => l.includes('── ')).length} Files</h3>
                            <p style={{ margin: 0, color: '#666' }}>Infrastructure as Code manifests</p>
                        </div>
                        <div style={cardStyle}>
                            <h3 style={{ margin: '0 0 10px' }}>📂 {treeStructure.match(/├──|└──/g).filter(l => !l.includes('.')).length || 21} Directories</h3>
                            <p style={{ margin: 0, color: '#666' }}>Logical separation of concerns</p>
                        </div>
                        <div style={cardStyle}>
                            <h3 style={{ margin: '0 0 10px' }}>🐳 3 Microservices</h3>
                            <p style={{ margin: 0, color: '#666' }}>Frontend • API • Auth</p>
                        </div>
                        <div style={cardStyle}>
                            <h3 style={{ margin: '0 0 10px' }}>⚙️ Full CI/CD Pipeline</h3>
                            <p style={{ margin: 0, color: '#666' }}>Jenkins • Kaniko • GitOps</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer style={{
                background: '#1a1a2e',
                color: 'white',
                textAlign: 'center',
                padding: '20px',
                fontSize: '0.9em',
                opacity: 0.7
            }}>
                DevOps Platform • Built with Kubernetes & React
            </footer>
        </div>
    );
}

const cardStyle = {
    background: 'white',
    padding: '20px',
    borderRadius: '8px',
    marginBottom: '15px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
    borderLeft: '4px solid #1a1a2e'
};

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);