package hydra.ext.sql.ansi;

public class DateLiteral {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/sql/ansi.DateLiteral");
  
  public final hydra.ext.sql.ansi.DateString value;
  
  public DateLiteral (hydra.ext.sql.ansi.DateString value) {
    this.value = value;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof DateLiteral)) {
      return false;
    }
    DateLiteral o = (DateLiteral) (other);
    return value.equals(o.value);
  }
  
  @Override
  public int hashCode() {
    return 2 * value.hashCode();
  }
}