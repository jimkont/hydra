package hydra.langs.cypher.openCypher;

import java.io.Serializable;

public class Quantifier implements Serializable {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/langs/cypher/openCypher.Quantifier");
  
  public final hydra.langs.cypher.openCypher.QuantifierType type;
  
  public final hydra.langs.cypher.openCypher.FilterExpression expression;
  
  public Quantifier (hydra.langs.cypher.openCypher.QuantifierType type, hydra.langs.cypher.openCypher.FilterExpression expression) {
    this.type = type;
    this.expression = expression;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof Quantifier)) {
      return false;
    }
    Quantifier o = (Quantifier) (other);
    return type.equals(o.type) && expression.equals(o.expression);
  }
  
  @Override
  public int hashCode() {
    return 2 * type.hashCode() + 3 * expression.hashCode();
  }
  
  public Quantifier withType(hydra.langs.cypher.openCypher.QuantifierType type) {
    return new Quantifier(type, expression);
  }
  
  public Quantifier withExpression(hydra.langs.cypher.openCypher.FilterExpression expression) {
    return new Quantifier(type, expression);
  }
}