package hydra.ext.sql.ansi;

public class ArrayElementList {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/sql/ansi.ArrayElementList");
  
  public final hydra.ext.sql.ansi.ArrayElement first;
  
  public final java.util.List<hydra.ext.sql.ansi.ArrayElement> rest;
  
  public ArrayElementList (hydra.ext.sql.ansi.ArrayElement first, java.util.List<hydra.ext.sql.ansi.ArrayElement> rest) {
    this.first = first;
    this.rest = rest;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof ArrayElementList)) {
      return false;
    }
    ArrayElementList o = (ArrayElementList) (other);
    return first.equals(o.first) && rest.equals(o.rest);
  }
  
  @Override
  public int hashCode() {
    return 2 * first.hashCode() + 3 * rest.hashCode();
  }
  
  public ArrayElementList withFirst(hydra.ext.sql.ansi.ArrayElement first) {
    return new ArrayElementList(first, rest);
  }
  
  public ArrayElementList withRest(java.util.List<hydra.ext.sql.ansi.ArrayElement> rest) {
    return new ArrayElementList(first, rest);
  }
}