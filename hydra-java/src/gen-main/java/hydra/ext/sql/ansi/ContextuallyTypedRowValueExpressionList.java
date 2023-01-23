package hydra.ext.sql.ansi;

public class ContextuallyTypedRowValueExpressionList {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/sql/ansi.ContextuallyTypedRowValueExpressionList");
  
  public final hydra.ext.sql.ansi.ContextuallyTypedRowValueExpression first;
  
  public final java.util.List<hydra.ext.sql.ansi.ContextuallyTypedRowValueExpression> rest;
  
  public ContextuallyTypedRowValueExpressionList (hydra.ext.sql.ansi.ContextuallyTypedRowValueExpression first, java.util.List<hydra.ext.sql.ansi.ContextuallyTypedRowValueExpression> rest) {
    this.first = first;
    this.rest = rest;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof ContextuallyTypedRowValueExpressionList)) {
      return false;
    }
    ContextuallyTypedRowValueExpressionList o = (ContextuallyTypedRowValueExpressionList) (other);
    return first.equals(o.first) && rest.equals(o.rest);
  }
  
  @Override
  public int hashCode() {
    return 2 * first.hashCode() + 3 * rest.hashCode();
  }
  
  public ContextuallyTypedRowValueExpressionList withFirst(hydra.ext.sql.ansi.ContextuallyTypedRowValueExpression first) {
    return new ContextuallyTypedRowValueExpressionList(first, rest);
  }
  
  public ContextuallyTypedRowValueExpressionList withRest(java.util.List<hydra.ext.sql.ansi.ContextuallyTypedRowValueExpression> rest) {
    return new ContextuallyTypedRowValueExpressionList(first, rest);
  }
}