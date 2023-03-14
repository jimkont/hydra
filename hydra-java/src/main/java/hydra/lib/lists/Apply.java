package hydra.lib.lists;

import hydra.core.Name;
import hydra.core.Type;
import hydra.tools.PrimitiveFunction;

import java.util.function.Function;
import java.util.List;
import java.util.stream.Collectors;
import static hydra.dsl.Types.*;


public class Apply<A> extends PrimitiveFunction<A> {
    public Name name() {
        return new Name("hydra/lib/lists.apply");
    }

    @Override
    public Type<A> type() {
        return lambda("x", lambda("y", function(function("x", "y"), list("x"), list("y"))));
    }

    public static <X, Y> Function<List<X>, List<Y>> apply(List<Function<X, Y>> functions) {
        return (args) -> apply(functions, args);
    }

    public static <X, Y> List<Y> apply(List<Function<X, Y>> functions, List<X> args) {
        return functions.stream().flatMap(f -> args.stream().map(f)).collect(Collectors.toList());
    }
}