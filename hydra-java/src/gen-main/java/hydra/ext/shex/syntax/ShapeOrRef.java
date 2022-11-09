package hydra.ext.shex.syntax;

public abstract class ShapeOrRef {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/shex/syntax.ShapeOrRef");
  
  private ShapeOrRef () {
  
  }
  
  public abstract <R> R accept(Visitor<R> visitor) ;
  
  public interface Visitor<R> {
    R visit(ShapeDefinition instance) ;
    
    R visit(AtpNameLn instance) ;
    
    R visit(AtpNameNs instance) ;
    
    R visit(Sequence instance) ;
  }
  
  public interface PartialVisitor<R> extends Visitor<R> {
    default R otherwise(ShapeOrRef instance) {
      throw new IllegalStateException("Non-exhaustive patterns when matching: " + (instance));
    }
    
    default R visit(ShapeDefinition instance) {
      return otherwise((instance));
    }
    
    default R visit(AtpNameLn instance) {
      return otherwise((instance));
    }
    
    default R visit(AtpNameNs instance) {
      return otherwise((instance));
    }
    
    default R visit(Sequence instance) {
      return otherwise((instance));
    }
  }
  
  public static final class ShapeDefinition extends hydra.ext.shex.syntax.ShapeOrRef {
    public final hydra.ext.shex.syntax.ShapeDefinition value;
    
    public ShapeDefinition (hydra.ext.shex.syntax.ShapeDefinition value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof ShapeDefinition)) {
        return false;
      }
      ShapeDefinition o = (ShapeDefinition) (other);
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
  
  public static final class AtpNameLn extends hydra.ext.shex.syntax.ShapeOrRef {
    public final hydra.ext.shex.syntax.AtpNameLn value;
    
    public AtpNameLn (hydra.ext.shex.syntax.AtpNameLn value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof AtpNameLn)) {
        return false;
      }
      AtpNameLn o = (AtpNameLn) (other);
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
  
  public static final class AtpNameNs extends hydra.ext.shex.syntax.ShapeOrRef {
    public final hydra.ext.shex.syntax.AtpNameNs value;
    
    public AtpNameNs (hydra.ext.shex.syntax.AtpNameNs value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof AtpNameNs)) {
        return false;
      }
      AtpNameNs o = (AtpNameNs) (other);
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
  
  public static final class Sequence extends hydra.ext.shex.syntax.ShapeOrRef {
    public final hydra.ext.shex.syntax.ShapeOrRef_Sequence value;
    
    public Sequence (hydra.ext.shex.syntax.ShapeOrRef_Sequence value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Sequence)) {
        return false;
      }
      Sequence o = (Sequence) (other);
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