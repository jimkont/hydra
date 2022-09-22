package hydra.evaluation;

/**
 * A container for logging and error information
 */
public class Trace {
  public static final hydra.core.Name NAME = new hydra.core.Name("hydra/evaluation.Trace");
  
  public final java.util.List<String> stack;
  
  public final java.util.List<String> messages;
  
  public final java.util.Map<String, hydra.core.Literal> other;
  
  public Trace (java.util.List<String> stack, java.util.List<String> messages, java.util.Map<String, hydra.core.Literal> other) {
    this.stack = stack;
    this.messages = messages;
    this.other = other;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof Trace)) {
      return false;
    }
    Trace o = (Trace) (other);
    return stack.equals(o.stack) && messages.equals(o.messages) && other.equals(o.other);
  }
  
  @Override
  public int hashCode() {
    return 2 * stack.hashCode() + 3 * messages.hashCode() + 5 * other.hashCode();
  }
  
  public Trace withStack(java.util.List<String> stack) {
    return new Trace(stack, messages, other);
  }
  
  public Trace withMessages(java.util.List<String> messages) {
    return new Trace(stack, messages, other);
  }
  
  public Trace withOther(java.util.Map<String, hydra.core.Literal> other) {
    return new Trace(stack, messages, other);
  }
}