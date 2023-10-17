package hydra.langs.cypher.openCypher;

import java.io.Serializable;

public abstract class ReadingClause implements Serializable {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/langs/cypher/openCypher.ReadingClause");
  
  private ReadingClause () {
  
  }
  
  public abstract <R> R accept(Visitor<R> visitor) ;
  
  public interface Visitor<R> {
    R visit(Match instance) ;
    
    R visit(Unwind instance) ;
    
    R visit(Call instance) ;
  }
  
  public interface PartialVisitor<R> extends Visitor<R> {
    default R otherwise(ReadingClause instance) {
      throw new IllegalStateException("Non-exhaustive patterns when matching: " + (instance));
    }
    
    default R visit(Match instance) {
      return otherwise((instance));
    }
    
    default R visit(Unwind instance) {
      return otherwise((instance));
    }
    
    default R visit(Call instance) {
      return otherwise((instance));
    }
  }
  
  public static final class Match extends hydra.langs.cypher.openCypher.ReadingClause implements Serializable {
    public final hydra.langs.cypher.openCypher.Match value;
    
    public Match (hydra.langs.cypher.openCypher.Match value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Match)) {
        return false;
      }
      Match o = (Match) (other);
      return value.equals(o.value);
    }
    
    @Override
    public int hashCode() {
      return 2 * value.hashCode();
    }
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
  }
  
  public static final class Unwind extends hydra.langs.cypher.openCypher.ReadingClause implements Serializable {
    public final hydra.langs.cypher.openCypher.Unwind value;
    
    public Unwind (hydra.langs.cypher.openCypher.Unwind value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Unwind)) {
        return false;
      }
      Unwind o = (Unwind) (other);
      return value.equals(o.value);
    }
    
    @Override
    public int hashCode() {
      return 2 * value.hashCode();
    }
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
  }
  
  public static final class Call extends hydra.langs.cypher.openCypher.ReadingClause implements Serializable {
    public final hydra.langs.cypher.openCypher.InQueryCall value;
    
    public Call (hydra.langs.cypher.openCypher.InQueryCall value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Call)) {
        return false;
      }
      Call o = (Call) (other);
      return value.equals(o.value);
    }
    
    @Override
    public int hashCode() {
      return 2 * value.hashCode();
    }
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
  }
}