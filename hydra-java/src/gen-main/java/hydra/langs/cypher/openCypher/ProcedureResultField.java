package hydra.langs.cypher.openCypher;

import java.io.Serializable;

public class ProcedureResultField implements Serializable {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/langs/cypher/openCypher.ProcedureResultField");
  
  public final String value;
  
  public ProcedureResultField (String value) {
    this.value = value;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof ProcedureResultField)) {
      return false;
    }
    ProcedureResultField o = (ProcedureResultField) (other);
    return value.equals(o.value);
  }
  
  @Override
  public int hashCode() {
    return 2 * value.hashCode();
  }
}