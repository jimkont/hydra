package hydra.ext.graphql.syntax;

public class ListType {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/graphql/syntax.ListType");
  
  public final hydra.ext.graphql.syntax.Type value;
  
  public ListType (hydra.ext.graphql.syntax.Type value) {
    this.value = value;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof ListType)) {
      return false;
    }
    ListType o = (ListType) (other);
    return value.equals(o.value);
  }
  
  @Override
  public int hashCode() {
    return 2 * value.hashCode();
  }
}