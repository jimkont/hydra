package hydra.langs.tinkerpop.propertyGraph;

/**
 * The type of a vertex
 */
public class VertexType<V, P> {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/langs/tinkerpop/propertyGraph.VertexType");
  
  public final hydra.langs.tinkerpop.propertyGraph.VertexLabel label;
  
  public final V id;
  
  public final java.util.Map<hydra.langs.tinkerpop.propertyGraph.PropertyKey, P> properties;
  
  public VertexType (hydra.langs.tinkerpop.propertyGraph.VertexLabel label, V id, java.util.Map<hydra.langs.tinkerpop.propertyGraph.PropertyKey, P> properties) {
    this.label = label;
    this.id = id;
    this.properties = properties;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof VertexType)) {
      return false;
    }
    VertexType o = (VertexType) (other);
    return label.equals(o.label) && id.equals(o.id) && properties.equals(o.properties);
  }
  
  @Override
  public int hashCode() {
    return 2 * label.hashCode() + 3 * id.hashCode() + 5 * properties.hashCode();
  }
  
  public VertexType withLabel(hydra.langs.tinkerpop.propertyGraph.VertexLabel label) {
    return new VertexType(label, id, properties);
  }
  
  public VertexType withId(V id) {
    return new VertexType(label, id, properties);
  }
  
  public VertexType withProperties(java.util.Map<hydra.langs.tinkerpop.propertyGraph.PropertyKey, P> properties) {
    return new VertexType(label, id, properties);
  }
}