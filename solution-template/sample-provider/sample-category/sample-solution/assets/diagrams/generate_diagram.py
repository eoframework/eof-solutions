#!/usr/bin/env python3
"""
Architecture Diagram Generator — Starter Template

BEFORE EDITING THIS FILE:
1. Read metadata.yml — identify your `provider` field (aws / azure / gcp / onprem / k8s / etc.)
2. Read eof-tools/guidance/diagrams/DIAGRAMS.md — authoritative guide covering:
   - How to resolve vendor-specific icon imports from the provider field
   - EO brand standards (cluster colours, edge styles, layout direction)
   - Worked examples for AWS, Azure, and GCP
3. Replace the generic icons below with provider-specific imports
4. Redefine clusters, nodes, and edges to match your solution architecture
5. Replace DIAGRAM_REQUIREMENTS.md with your solution's component specifications

Prerequisites:
    pip install diagrams
    sudo apt-get install graphviz    # Ubuntu/Debian/WSL
    brew install graphviz             # macOS
    choco install graphviz            # Windows

Usage:
    python3 generate_diagram.py
    # Output: architecture-diagram.png
"""

import sys
sys.path.insert(0, '/mnt/c/projects/wsl/eof-tools/utils')
from diagram_utils import GRAPH_ATTR, NODE_ATTR, EDGE_ATTR, EO_CLUSTER_COLOURS

from diagrams import Diagram, Cluster, Edge

# ── Replace these generic imports with provider-specific icons ────────────────
# Read eof-tools/guidance/diagrams/DIAGRAMS.md to find the correct imports
# for your provider (aws, azure, gcp, onprem, k8s, etc.)
# ─────────────────────────────────────────────────────────────────────────────
from diagrams.generic.compute import Rack
from diagrams.generic.network import Firewall, Router
from diagrams.generic.storage import Storage
from diagrams.generic.database import SQL
from diagrams.onprem.client import Users


# ── Replace diagram title and filename ───────────────────────────────────────
with Diagram(
    "Solution Architecture",          # Update: solution name
    filename="architecture-diagram",  # Do not change: output filename
    show=False,
    direction="LR",                   # LR = left-to-right; TB = top-to-bottom
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
):

    # ── External users / on-premises systems ─────────────────────────────────
    users = Users("End Users")

    # ── Replace cluster names and colours based on your solution ─────────────
    # Available colours: management, security, network, workload, identity,
    #                    external, data, devops
    # See eof-tools/utils/diagram_utils.py for hex values
    # ─────────────────────────────────────────────────────────────────────────

    with Cluster("Control Plane", graph_attr={"bgcolor": EO_CLUSTER_COLOURS["management"]}):
        control = Rack("Control Service")

    with Cluster("Network Layer", graph_attr={"bgcolor": EO_CLUSTER_COLOURS["network"]}):
        fw = Firewall("Firewall")
        router = Router("Load Balancer")

    with Cluster("Application Layer", graph_attr={"bgcolor": EO_CLUSTER_COLOURS["workload"]}):
        app = Rack("Application")

    with Cluster("Data Layer", graph_attr={"bgcolor": EO_CLUSTER_COLOURS["data"]}):
        db = SQL("Database")
        store = Storage("Storage")

    # ── Replace connections with actual data flows ────────────────────────────
    # See DIAGRAMS.md for edge style conventions (solid, dashed, dotted)
    # ─────────────────────────────────────────────────────────────────────────
    users >> Edge(label="HTTPS") >> fw
    fw >> Edge(label="Filtered") >> router
    router >> Edge(label="Routes") >> app
    app >> Edge(label="Query") >> db
    app >> Edge(label="Store") >> store
    control >> Edge(label="Governs", style="dotted") >> app


print("Architecture diagram generated: architecture-diagram.png")
