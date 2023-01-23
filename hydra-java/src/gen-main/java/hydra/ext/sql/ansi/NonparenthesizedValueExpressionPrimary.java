package hydra.ext.sql.ansi;

public abstract class NonparenthesizedValueExpressionPrimary {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/ext/sql/ansi.NonparenthesizedValueExpressionPrimary");
  
  private NonparenthesizedValueExpressionPrimary () {
  
  }
  
  public abstract <R> R accept(Visitor<R> visitor) ;
  
  public interface Visitor<R> {
    R visit(Unsigned instance) ;
    
    R visit(Column instance) ;
    
    R visit(SetFunction instance) ;
    
    R visit(WindowFunction instance) ;
    
    R visit(ScalarSubquery instance) ;
    
    R visit(Cases instance) ;
    
    R visit(Cast instance) ;
    
    R visit(Field instance) ;
    
    R visit(Subtype instance) ;
    
    R visit(Method instance) ;
    
    R visit(StaticMethod instance) ;
    
    R visit(New instance) ;
    
    R visit(AttributeOrMethod instance) ;
    
    R visit(Reference instance) ;
    
    R visit(Collection instance) ;
    
    R visit(ArrayElement instance) ;
    
    R visit(MultisetElement instance) ;
    
    R visit(Routine instance) ;
    
    R visit(Next instance) ;
  }
  
  public interface PartialVisitor<R> extends Visitor<R> {
    default R otherwise(NonparenthesizedValueExpressionPrimary instance) {
      throw new IllegalStateException("Non-exhaustive patterns when matching: " + (instance));
    }
    
    default R visit(Unsigned instance) {
      return otherwise((instance));
    }
    
    default R visit(Column instance) {
      return otherwise((instance));
    }
    
    default R visit(SetFunction instance) {
      return otherwise((instance));
    }
    
    default R visit(WindowFunction instance) {
      return otherwise((instance));
    }
    
    default R visit(ScalarSubquery instance) {
      return otherwise((instance));
    }
    
    default R visit(Cases instance) {
      return otherwise((instance));
    }
    
    default R visit(Cast instance) {
      return otherwise((instance));
    }
    
    default R visit(Field instance) {
      return otherwise((instance));
    }
    
    default R visit(Subtype instance) {
      return otherwise((instance));
    }
    
    default R visit(Method instance) {
      return otherwise((instance));
    }
    
    default R visit(StaticMethod instance) {
      return otherwise((instance));
    }
    
    default R visit(New instance) {
      return otherwise((instance));
    }
    
    default R visit(AttributeOrMethod instance) {
      return otherwise((instance));
    }
    
    default R visit(Reference instance) {
      return otherwise((instance));
    }
    
    default R visit(Collection instance) {
      return otherwise((instance));
    }
    
    default R visit(ArrayElement instance) {
      return otherwise((instance));
    }
    
    default R visit(MultisetElement instance) {
      return otherwise((instance));
    }
    
    default R visit(Routine instance) {
      return otherwise((instance));
    }
    
    default R visit(Next instance) {
      return otherwise((instance));
    }
  }
  
  public static final class Unsigned extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.UnsignedValueSpecification value;
    
    public Unsigned (hydra.ext.sql.ansi.UnsignedValueSpecification value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Unsigned)) {
        return false;
      }
      Unsigned o = (Unsigned) (other);
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
  
  public static final class Column extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.ColumnReference value;
    
    public Column (hydra.ext.sql.ansi.ColumnReference value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Column)) {
        return false;
      }
      Column o = (Column) (other);
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
  
  public static final class SetFunction extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.SetFunctionSpecification value;
    
    public SetFunction (hydra.ext.sql.ansi.SetFunctionSpecification value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof SetFunction)) {
        return false;
      }
      SetFunction o = (SetFunction) (other);
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
  
  public static final class WindowFunction extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.WindowFunction value;
    
    public WindowFunction (hydra.ext.sql.ansi.WindowFunction value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof WindowFunction)) {
        return false;
      }
      WindowFunction o = (WindowFunction) (other);
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
  
  public static final class ScalarSubquery extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.ScalarSubquery value;
    
    public ScalarSubquery (hydra.ext.sql.ansi.ScalarSubquery value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof ScalarSubquery)) {
        return false;
      }
      ScalarSubquery o = (ScalarSubquery) (other);
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
  
  public static final class Cases extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.CaseExpression value;
    
    public Cases (hydra.ext.sql.ansi.CaseExpression value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Cases)) {
        return false;
      }
      Cases o = (Cases) (other);
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
  
  public static final class Cast extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.CastSpecification value;
    
    public Cast (hydra.ext.sql.ansi.CastSpecification value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Cast)) {
        return false;
      }
      Cast o = (Cast) (other);
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
  
  public static final class Field extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.FieldReference value;
    
    public Field (hydra.ext.sql.ansi.FieldReference value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Field)) {
        return false;
      }
      Field o = (Field) (other);
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
  
  public static final class Subtype extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.SubtypeTreatment value;
    
    public Subtype (hydra.ext.sql.ansi.SubtypeTreatment value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Subtype)) {
        return false;
      }
      Subtype o = (Subtype) (other);
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
  
  public static final class Method extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.MethodInvocation value;
    
    public Method (hydra.ext.sql.ansi.MethodInvocation value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Method)) {
        return false;
      }
      Method o = (Method) (other);
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
  
  public static final class StaticMethod extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.StaticMethodInvocation value;
    
    public StaticMethod (hydra.ext.sql.ansi.StaticMethodInvocation value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof StaticMethod)) {
        return false;
      }
      StaticMethod o = (StaticMethod) (other);
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
  
  public static final class New extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.NewSpecification value;
    
    public New (hydra.ext.sql.ansi.NewSpecification value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof New)) {
        return false;
      }
      New o = (New) (other);
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
  
  public static final class AttributeOrMethod extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.AttributeOrMethodReference value;
    
    public AttributeOrMethod (hydra.ext.sql.ansi.AttributeOrMethodReference value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof AttributeOrMethod)) {
        return false;
      }
      AttributeOrMethod o = (AttributeOrMethod) (other);
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
  
  public static final class Reference extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.ReferenceResolution value;
    
    public Reference (hydra.ext.sql.ansi.ReferenceResolution value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Reference)) {
        return false;
      }
      Reference o = (Reference) (other);
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
  
  public static final class Collection extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.CollectionValueConstructor value;
    
    public Collection (hydra.ext.sql.ansi.CollectionValueConstructor value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Collection)) {
        return false;
      }
      Collection o = (Collection) (other);
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
  
  public static final class ArrayElement extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.ArrayElementReference value;
    
    public ArrayElement (hydra.ext.sql.ansi.ArrayElementReference value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof ArrayElement)) {
        return false;
      }
      ArrayElement o = (ArrayElement) (other);
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
  
  public static final class MultisetElement extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.MultisetElementReference value;
    
    public MultisetElement (hydra.ext.sql.ansi.MultisetElementReference value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof MultisetElement)) {
        return false;
      }
      MultisetElement o = (MultisetElement) (other);
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
  
  public static final class Routine extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.RoutineInvocation value;
    
    public Routine (hydra.ext.sql.ansi.RoutineInvocation value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Routine)) {
        return false;
      }
      Routine o = (Routine) (other);
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
  
  public static final class Next extends hydra.ext.sql.ansi.NonparenthesizedValueExpressionPrimary {
    public final hydra.ext.sql.ansi.NextValueExpression value;
    
    public Next (hydra.ext.sql.ansi.NextValueExpression value) {
      this.value = value;
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Next)) {
        return false;
      }
      Next o = (Next) (other);
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