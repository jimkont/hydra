package hydra.lib.sets;

import hydra.core.Name;
import hydra.tools.PrimitiveFunction;

import java.util.Collections;
import java.util.Set;

public class Empty<A> extends PrimitiveFunction<A> {
    public Name name() {
        return new Name("hydra/lib/sets.empty");
    }

    public static <X> Set<X> apply() {
        return Collections.emptySet();
    }
}
