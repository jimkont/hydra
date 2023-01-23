package hydra.ext.graphql.syntax;

public class Arguments {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/graphql/syntax.Arguments");
  
  public final java.util.List<hydra.ext.graphql.syntax.Argument> value;
  
  public Arguments (java.util.List<hydra.ext.graphql.syntax.Argument> value) {
    this.value = value;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof Arguments)) {
      return false;
    }
    Arguments o = (Arguments) (other);
    return value.equals(o.value);
  }
  
  @Override
  public int hashCode() {
    return 2 * value.hashCode();
  }
}