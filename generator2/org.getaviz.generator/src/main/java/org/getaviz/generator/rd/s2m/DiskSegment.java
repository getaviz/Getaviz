package org.getaviz.generator.rd.s2m;

import org.getaviz.generator.database.DatabaseConnector;
import org.getaviz.generator.database.Labels;
import org.neo4j.driver.v1.types.Node;

public class DiskSegment implements RDElement {

    private double size;
    private double height;
    private double transparency;
    private double netArea;
    private String color;
    private long visualizedNodeID;
    private long parentVisualizedNodeID;
    private long parentID;
    private long id;
    private Node node;

    DiskSegment (long visualizedNodeID, long parentVisualizedNodeID, double height, double transparency, String color) {
        this.visualizedNodeID = visualizedNodeID;
        this.parentVisualizedNodeID = parentVisualizedNodeID;
        this.size = 1.0;
        this.transparency = transparency;
        this.height = height;
        this.color = color;
    }

    DiskSegment (long visualizedNodeID, long parentVisualizedNodeID, double height, double transparency, double minArea, String color,
        int numberOfStatements) {
        this(visualizedNodeID, parentVisualizedNodeID, transparency, height, color);

        size = numberOfStatements;
        if (numberOfStatements <= minArea) {
            size = minArea;
        }
    }

    public DiskSegment (Node node, long parentID, long id, double size) {
        this.node = node;
        this.parentID = parentID;
        this.id = id;
        this.size = size;
    }

    public void writeToDatabase(DatabaseConnector connector) {
        String label = Labels.DiskSegment.name();
        long id = connector.addNode(String.format(
                "MATCH(parent),(s) WHERE ID(parent) = %d AND ID(s) = %d CREATE (parent)-[:CONTAINS]->" +
                        "(n:RD:%s {%s})-[:VISUALIZES]->(s)",
                parentID, visualizedNodeID, label, propertiesToString()), "n").id();
        setId(id);
    }

    public long getParentVisualizedNodeID(){
        return parentVisualizedNodeID;
    }

    public long getVisualizedNodeID() {
        return visualizedNodeID;
    }

   private String propertiesToString() {
        return String.format("size: %f, height: %f, transparency: %f, color: \'%s\'", size, height,
                transparency, color);
    }

    public long getId() {
        return id;
    }

    public long getParentID() {
        return parentID;
    }

    public double getSize() {
        return size;
    }

    public void setParentID(long newParentID) {
        this.parentID = newParentID;
    }

    private void setId(long id) {
        this.id = id;
    }

    public void setNetArea(double netArea) {
       this.netArea = netArea;
    }

    public void setSize(double size) {
        this.size = size;
    }
}