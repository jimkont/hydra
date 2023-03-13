package hydra.lib.lists;

import hydra.core.Name;
import hydra.tools.PrimitiveFunction;

import java.util.function.Function;
import java.util.List;
import java.util.stream.Collectors;

public class Map<A> extends PrimitiveFunction<A> {
    public Name name() {
        return new Name("hydra/lib/lists.map");
    }

    public static <X, Y> Function<List<X>, List<Y>> apply(Function<X, Y> mapping) {
        return (arg) -> apply(mapping, arg);
    }

    public static <X, Y> List<Y> apply(Function<X, Y> mapping, List<X> arg) {
        return arg.stream().map(mapping).collect(Collectors.toList());
    }
}
